import os
import posixpath
import shlex
import sys
from datetime import datetime, timezone
from pathlib import Path

import paramiko


if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = Path(__file__).resolve().parent.parent
SYNC = ROOT / "_website_sync"
PUBLIC_HTML = "/home/adminanmkavps/web/bouslty.anmka.com/public_html"


def q(value):
    return shlex.quote(str(value))


client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(
    "77.237.232.181",
    port=2222,
    username="root",
    password=os.environ["SSH_PASS"],
    timeout=40,
    allow_agent=False,
    look_for_keys=False,
)


def run(command, timeout=1800, required=True):
    _, stdout, stderr = client.exec_command(command, timeout=timeout)
    output = stdout.read().decode("utf-8", "replace")
    error = stderr.read().decode("utf-8", "replace")
    status = stdout.channel.recv_exit_status()
    if output.strip():
        print(output[-18000:])
    if error.strip():
        print(error[-12000:])
    if required and status:
        raise RuntimeError(f"Remote command failed ({status})")
    return status


try:
    _, stdout, _ = client.exec_command(
        "pm2 describe bouslty-anmka-student | grep 'exec cwd'", timeout=30
    )
    raw = stdout.read().decode("utf-8", "replace")
    student = next(
        (line.split("│")[-2].strip() for line in raw.splitlines() if "exec cwd" in line),
        None,
    )
    if not student or not student.startswith("/"):
        raise RuntimeError("Student application directory was not found")

    files = [
        (SYNC / "components" / "role-portal.tsx", "components/role-portal.tsx"),
        (SYNC / "app" / "login-page.tsx", "app/login/page.tsx"),
        (SYNC / "app" / "chat" / "[conversationId]" / "page.tsx", "app/chat/[conversationId]/page.tsx"),
    ]
    for section in ("dashboard", "instructor"):
        base = SYNC / "app" / section
        for source in base.rglob("page.tsx"):
            relative = source.relative_to(SYNC).as_posix()
            files.append((source, relative))

    missing = [str(source) for source, _ in files if not source.is_file()]
    if missing:
        raise RuntimeError(f"Missing local files: {missing}")

    stamp = datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%S")
    backup = f"{PUBLIC_HTML}/deploy-backups/role-portals-{stamp}"
    previous_next = f"/tmp/bouslty-student-role-portals-next-{stamp}"
    run(
        f"mkdir -p {q(backup)} && test ! -d {q(f'{student}/.next')} || "
        f"cp -a {q(f'{student}/.next')} {q(previous_next)}"
    )

    originals = []
    for index, (_, relative) in enumerate(files):
        destination = f"{student}/{relative}"
        run(f"mkdir -p {q(posixpath.dirname(destination))}")
        exists = run(f"test -f {q(destination)}", required=False) == 0
        originals.append(exists)
        if exists:
            run(f"cp -a {q(destination)} {q(posixpath.join(backup, f'{index}.tsx'))}")

    sftp = client.open_sftp()
    try:
        for source, relative in files:
            destination = f"{student}/{relative}"
            temporary = f"{destination}.codex-upload"
            sftp.put(str(source), temporary)
            run(f"mv {q(temporary)} {q(destination)}")
    finally:
        sftp.close()

    build_status = run(f"cd {q(student)} && npm run build:direct", required=False)
    if build_status:
        for index, (_, relative) in enumerate(files):
            destination = f"{student}/{relative}"
            if originals[index]:
                run(f"cp -a {q(posixpath.join(backup, f'{index}.tsx'))} {q(destination)}", required=False)
            else:
                run(f"rm -f -- {q(destination)}", required=False)
        run(
            f"rm -rf {q(f'{student}/.next')} && cp -a {q(previous_next)} {q(f'{student}/.next')}",
            required=False,
        )
        raise RuntimeError("Website build failed; source and previous build were restored")

    run(
        "pm2 restart bouslty-anmka-student --update-env >/dev/null && sleep 4 && "
        "pm2 describe bouslty-anmka-student | grep -E 'status|restart time'"
    )
    run(
        "for route in dashboard instructor dashboard/bookings dashboard/messages instructor/requests instructor/calendar instructor/messages instructor/marketplace instructor/earnings; do "
        "code=$(curl -sS -o /dev/null -w '%{http_code}' https://bouslty.anmka.com/$route); "
        "printf '%s=%s\\n' \"$route\" \"$code\"; test \"$code\" = 200 || exit 1; done",
        timeout=120,
    )
    print(f"DEPLOY_OK backup={backup}")
finally:
    client.close()
