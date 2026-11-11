import os
import posixpath
import time

import paramiko


HOST = "77.237.232.181"
PORT = 2222
USER = "root"
REMOTE_BACKEND = "/home/adminanmkavps/web/bouslty.anmka.com/public_html/backend"
REMOTE_MIDDLEWARE = posixpath.join(
    REMOTE_BACKEND, "src/shared/middleware/upload.middleware.js"
)
LOCAL_MIDDLEWARE = os.path.join(
    os.path.dirname(__file__), "student-features-current", "upload.middleware.js"
)


def run(client, command):
    _, stdout, stderr = client.exec_command(command, timeout=120)
    output = stdout.read().decode("utf-8", "replace")
    error = stderr.read().decode("utf-8", "replace")
    status = stdout.channel.recv_exit_status()
    if output:
        print(output)
    if error:
        print(error)
    if status != 0:
        raise RuntimeError(f"Command failed ({status}): {command}")


client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(
    HOST,
    port=PORT,
    username=USER,
    password=os.environ["SSH_PASS"],
    timeout=40,
    allow_agent=False,
    look_for_keys=False,
)

stamp = time.strftime("%Y%m%d-%H%M%S")
run(client, f"cp '{REMOTE_MIDDLEWARE}' '{REMOTE_MIDDLEWARE}.bak-{stamp}'")

sftp = client.open_sftp()
sftp.put(LOCAL_MIDDLEWARE, REMOTE_MIDDLEWARE)
sftp.close()

run(client, f"cd '{REMOTE_BACKEND}' && node --check src/shared/middleware/upload.middleware.js")
run(client, "pm2 restart bouslty-anmka-lms-backend --update-env")
run(client, "pm2 describe bouslty-anmka-lms-backend | grep -E 'status|restart time'")
client.close()
