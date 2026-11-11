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
ADMIN = "/home/adminanmkavps/web/bouslty.anmka.com/public_html"
BACKEND = f"{ADMIN}/backend"


def quoted(value):
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


def run(command, timeout=1200, required=True):
    print(f"\n$ {command[:500]}", flush=True)
    _, stdout, stderr = client.exec_command(command, timeout=timeout)
    output = stdout.read().decode("utf-8", "replace")
    error = stderr.read().decode("utf-8", "replace")
    code = stdout.channel.recv_exit_status()
    if output:
        print(output[-20000:], flush=True)
    if error.strip():
        print(error[-12000:], flush=True)
    print(f"exit={code}", flush=True)
    if required and code:
        raise RuntimeError(f"Remote command failed ({code})")
    return code, output, error


try:
    _, process_output, _ = run("pm2 describe bouslty-anmka-student | grep 'exec cwd'")
    student = None
    for line in process_output.splitlines():
        if "exec cwd" in line:
            candidate = line.split("│")[-2].strip() if "│" in line else line.split()[-1]
            if candidate.startswith("/"):
                student = candidate
                break
    if not student:
        raise RuntimeError("Could not resolve the deployed student application directory")

    stamp = datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%S")
    backup = f"{ADMIN}/deploy-backups/{stamp}"
    uploads = [
        (ROOT / "live-current" / "student-instructors-page.tsx", f"{student}/app/instructors/page.tsx", "student-instructors-page.tsx"),
        (ROOT / "admin-marketplace-page.next.tsx", f"{ADMIN}/app/admin/marketplace/page.tsx", "admin-marketplace-page.tsx"),
        (ROOT / "live-current" / "admin-tutor-controls-page.tsx", f"{ADMIN}/app/admin/tutor-controls/page.tsx", "admin-tutor-controls-page.tsx"),
        (ROOT / "live-current" / "marketplace.service.js", f"{BACKEND}/src/modules/marketplace/marketplace.service.js", "marketplace.service.js"),
        (ROOT / "live-current" / "schema.prisma", f"{BACKEND}/prisma/schema.prisma", "schema.prisma"),
    ]
    missing = [str(source) for source, _, _ in uploads if not source.is_file()]
    if missing:
        raise RuntimeError(f"Missing deployment files: {missing}")

    run(f"mkdir -p {quoted(backup)} {quoted(f'{ADMIN}/app/admin/marketplace')} {quoted(f'{ADMIN}/app/admin/tutor-controls')}")
    for _, destination, backup_name in uploads:
        run(f"cp -a {quoted(destination)} {quoted(posixpath.join(backup, backup_name))}")

    sftp = client.open_sftp()
    try:
        for source, destination, _ in uploads:
            temporary = f"{destination}.codex-upload"
            print(f"upload {source.name} -> {destination}", flush=True)
            sftp.put(str(source), temporary)
            run(f"mv {quoted(temporary)} {quoted(destination)}")
    finally:
        sftp.close()

    run(f"node --check {quoted(f'{BACKEND}/src/modules/marketplace/marketplace.service.js')}")
    run(f"cd {quoted(BACKEND)} && npx prisma validate && npx prisma db push --skip-generate && npx prisma generate", timeout=1200)

    student_next = f"/tmp/bouslty-student-next-{stamp}"
    admin_next = f"/tmp/bouslty-admin-next-{stamp}"
    run(f"test ! -d {quoted(f'{student}/.next')} || cp -a {quoted(f'{student}/.next')} {quoted(student_next)}")
    student_code, _, _ = run(f"cd {quoted(student)} && npm run build:direct", timeout=1800, required=False)
    if student_code:
        run(f"rm -rf {quoted(f'{student}/.next')} && cp -a {quoted(student_next)} {quoted(f'{student}/.next')}", required=False)
        raise RuntimeError("Student build failed; previous compiled build was restored")

    run(f"test ! -d {quoted(f'{ADMIN}/.next')} || cp -a {quoted(f'{ADMIN}/.next')} {quoted(admin_next)}")
    admin_code, _, _ = run(f"cd {quoted(ADMIN)} && npm run build:direct", timeout=1800, required=False)
    if admin_code:
        run(f"rm -rf {quoted(f'{ADMIN}/.next')} && cp -a {quoted(admin_next)} {quoted(f'{ADMIN}/.next')}", required=False)
        raise RuntimeError("Admin build failed; previous compiled build was restored")

    run("pm2 restart bouslty-anmka-lms-backend bouslty-anmka-student bouslty-anmka-admin --update-env")
    run("sleep 5 && curl -fsS 'http://127.0.0.1:16821/api/categories' | head -c 800 && printf '\n' && curl -fsS -o /dev/null -w 'instructors=%{http_code}\n' 'https://bouslty.anmka.com/instructors' && curl -fsS 'https://bouslty.anmka.com/instructors' | grep -o 'اختار التصنيف' | head -1", timeout=60)
    print(f"DEPLOY_OK backup={backup}", flush=True)
finally:
    client.close()
