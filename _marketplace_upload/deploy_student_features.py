import os
import posixpath
import shlex
import sys
from datetime import datetime, timezone
from pathlib import Path

import paramiko

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

ROOT = Path(__file__).resolve().parent
FEATURES = ROOT / "student-features-current"
ADMIN = "/home/adminanmkavps/web/bouslty.anmka.com/public_html"
BACKEND = f"{ADMIN}/backend"


def q(value):
    return shlex.quote(str(value))


client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect("77.237.232.181", port=2222, username="root", password=os.environ["SSH_PASS"], timeout=40, allow_agent=False, look_for_keys=False)


def run(command, timeout=1800, required=True):
    print(f"\n$ {command[:500]}", flush=True)
    _, stdout, stderr = client.exec_command(command, timeout=timeout)
    out = stdout.read().decode("utf-8", "replace")
    err = stderr.read().decode("utf-8", "replace")
    code = stdout.channel.recv_exit_status()
    if out:
        print(out[-20000:], flush=True)
    if err.strip():
        print(err[-12000:], flush=True)
    print(f"exit={code}", flush=True)
    if required and code:
        raise RuntimeError(f"remote command failed ({code})")
    return code


try:
    _, stdout, _ = client.exec_command("pm2 describe bouslty-anmka-student | grep 'exec cwd'", timeout=30)
    raw = stdout.read().decode("utf-8", "replace")
    student = next((line.split("│")[-2].strip() for line in raw.splitlines() if "exec cwd" in line), None)
    if not student or not student.startswith("/"):
        raise RuntimeError("student cwd not found")

    stamp = datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%S")
    backup = f"{ADMIN}/deploy-backups/student-features-{stamp}"
    uploads = [
        (FEATURES / "dashboard-chat-detail-page.tsx", f"{student}/app/dashboard/chat/[id]/page.tsx", "dashboard-chat-detail-page.tsx"),
        (FEATURES / "dashboard-chat-page.tsx", f"{student}/app/dashboard/chat/page.tsx", "dashboard-chat-page.tsx"),
        (FEATURES / "marketplace-booking.tsx", f"{student}/components/marketplace-booking.tsx", "marketplace-booking.tsx"),
        (FEATURES / "dashboard-page.tsx", f"{student}/app/dashboard/page.tsx", "dashboard-page.tsx"),
        (FEATURES / "dashboard-bookings-page.tsx", f"{student}/app/dashboard/bookings/page.tsx", "dashboard-bookings-page.tsx"),
        (FEATURES / "student-api.ts", f"{student}/lib/api.ts", "student-api.ts"),
        (FEATURES / "chat.routes.js", f"{BACKEND}/src/modules/chat/chat.routes.js", "chat.routes.js"),
        (FEATURES / "chat.controller.js", f"{BACKEND}/src/modules/chat/chat.controller.js", "chat.controller.js"),
        (FEATURES / "chat.service.js", f"{BACKEND}/src/modules/chat/chat.service.js", "chat.service.js"),
        (FEATURES / "chat.schema.js", f"{BACKEND}/src/modules/chat/chat.schema.js", "chat.schema.js"),
        (FEATURES / "upload.middleware.js", f"{BACKEND}/src/shared/middleware/upload.middleware.js", "upload.middleware.js"),
        (ROOT / "live-current" / "schema.prisma", f"{BACKEND}/prisma/schema.prisma", "schema.prisma"),
    ]
    missing = [str(source) for source, _, _ in uploads if not source.is_file()]
    if missing:
        raise RuntimeError(f"missing deployment files: {missing}")

    run(f"mkdir -p {q(backup)}")
    for _, destination, name in uploads:
        run(f"cp -a {q(destination)} {q(posixpath.join(backup, name))}")

    sftp = client.open_sftp()
    try:
        for source, destination, _ in uploads:
            temporary = f"{destination}.codex-upload"
            print(f"upload {source.name} -> {destination}", flush=True)
            sftp.put(str(source), temporary)
            run(f"mv {q(temporary)} {q(destination)}")
    finally:
        sftp.close()

    run(f"node --check {q(f'{BACKEND}/src/modules/chat/chat.service.js')} && node --check {q(f'{BACKEND}/src/modules/chat/chat.controller.js')} && node --check {q(f'{BACKEND}/src/modules/chat/chat.schema.js')}")
    run(f"cd {q(BACKEND)} && npx prisma validate && npx prisma db push --skip-generate && npx prisma generate")

    previous_next = f"/tmp/bouslty-student-next-{stamp}"
    run(f"test ! -d {q(f'{student}/.next')} || cp -a {q(f'{student}/.next')} {q(previous_next)}")
    build_code = run(f"cd {q(student)} && npm run build:direct", required=False)
    if build_code:
        run(f"rm -rf {q(f'{student}/.next')} && cp -a {q(previous_next)} {q(f'{student}/.next')}", required=False)
        raise RuntimeError("student build failed; previous compiled build restored")

    run("pm2 restart bouslty-anmka-lms-backend bouslty-anmka-student --update-env")
    run("sleep 5 && curl -fsS -o /dev/null -w 'instructors=%{http_code}\nchat=%{http_code}\nbookings=%{http_code}\n' https://bouslty.anmka.com/instructors https://bouslty.anmka.com/dashboard/chat https://bouslty.anmka.com/dashboard/bookings", timeout=60)
    print(f"DEPLOY_OK backup={backup}", flush=True)
finally:
    client.close()
