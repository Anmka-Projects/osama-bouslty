import os
import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect("77.237.232.181", port=2222, username="root", password=os.environ["SSH_PASS"], timeout=40, allow_agent=False, look_for_keys=False)
commands = [
    "pm2 logs bouslty-anmka-lms-backend --lines 350 --nostream 2>&1 | grep -Ei 'upload|audio|multer|chat|error|enoent|unsupported|validation' | tail -100",
    "pm2 describe bouslty-anmka-lms-backend | grep -E 'exec cwd|script path|status'",
    "find /home/adminanmkavps/web/bouslty.anmka.com/public_html -path '*/uploads/*' -type f -mmin -240 -printf '%TY-%Tm-%Td %TH:%TM %s %p\\n' 2>/dev/null | tail -50",
]
for command in commands:
    _, stdout, stderr = client.exec_command(command, timeout=60)
    print(stdout.read().decode("utf-8", "replace"))
    print(stderr.read().decode("utf-8", "replace"))
client.close()
