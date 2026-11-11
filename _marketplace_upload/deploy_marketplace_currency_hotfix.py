import os
import posixpath
import time

import paramiko


LOCAL = os.path.join(os.path.dirname(__file__), "live-current", "marketplace.service.js")
BACKEND = "/home/adminanmkavps/web/bouslty.anmka.com/public_html/backend"
REMOTE = posixpath.join(BACKEND, "src/modules/marketplace/marketplace.service.js")
BACKUP_DIR = "/home/adminanmkavps/web/bouslty.anmka.com/public_html/deploy-backups"

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


def run(command, timeout=120):
    _, stdout, stderr = client.exec_command(command, timeout=timeout)
    output = stdout.read().decode("utf-8", "replace")
    error = stderr.read().decode("utf-8", "replace")
    status = stdout.channel.recv_exit_status()
    if output.strip():
        print(output[-6000:])
    if error.strip():
        print(error[-4000:])
    if status:
        raise RuntimeError(f"Remote command failed ({status})")


try:
    stamp = time.strftime("%Y%m%d-%H%M%S")
    backup = posixpath.join(BACKUP_DIR, f"marketplace-currency-{stamp}.service.js")
    run(f"mkdir -p '{BACKUP_DIR}' && cp -a '{REMOTE}' '{backup}'")
    temporary = f"{REMOTE}.codex-upload"
    sftp = client.open_sftp()
    try:
        sftp.put(LOCAL, temporary)
        sftp.posix_rename(temporary, REMOTE)
    finally:
        sftp.close()
    run(f"cd '{BACKEND}' && node --check src/modules/marketplace/marketplace.service.js")
    run(
        "pm2 restart bouslty-anmka-lms-backend --update-env >/dev/null && "
        "sleep 4 && pm2 describe bouslty-anmka-lms-backend | grep -E 'status|restart time'"
    )
    run("curl -fsS -o /dev/null -w 'api=%{http_code}\\n' https://bouslty.anmka.com/api/trainers?per_page=1")
    print(f"DEPLOY_OK backup={backup}")
finally:
    client.close()
