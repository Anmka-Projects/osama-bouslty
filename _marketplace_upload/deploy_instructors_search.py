import os
import posixpath
import shlex
import sys
from datetime import datetime, timezone
from pathlib import Path

import paramiko


if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = Path(__file__).resolve().parent
LOCAL_PAGE = ROOT / "live-current" / "student-instructors-page.tsx"
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
        print(output[-16000:])
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

    stamp = datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%S")
    destination = f"{student}/app/instructors/page.tsx"
    backup = f"{PUBLIC_HTML}/deploy-backups/instructors-search-{stamp}"
    previous_next = f"/tmp/bouslty-student-instructors-next-{stamp}"
    run(
        f"mkdir -p {q(backup)} && cp -a {q(destination)} "
        f"{q(posixpath.join(backup, 'page.tsx'))} && "
        f"test ! -d {q(f'{student}/.next')} || cp -a {q(f'{student}/.next')} {q(previous_next)}"
    )

    temporary = f"{destination}.codex-upload"
    sftp = client.open_sftp()
    try:
        sftp.put(str(LOCAL_PAGE), temporary)
    finally:
        sftp.close()
    run(f"mv {q(temporary)} {q(destination)}")

    build_status = run(f"cd {q(student)} && npm run build:direct", required=False)
    if build_status:
        run(
            f"cp -a {q(posixpath.join(backup, 'page.tsx'))} {q(destination)} && "
            f"rm -rf {q(f'{student}/.next')} && cp -a {q(previous_next)} {q(f'{student}/.next')}",
            required=False,
        )
        raise RuntimeError("Website build failed; source and previous build were restored")

    run(
        "pm2 restart bouslty-anmka-student --update-env >/dev/null && "
        "sleep 4 && pm2 describe bouslty-anmka-student | grep -E 'status|restart time'"
    )
    run(
        "curl -fsS -o /dev/null -w 'instructors=%{http_code}\\n' "
        "https://bouslty.anmka.com/instructors",
        timeout=60,
    )
    print(f"DEPLOY_OK backup={backup}")
finally:
    client.close()
