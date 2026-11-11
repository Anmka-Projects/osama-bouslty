import os
import paramiko

password = os.environ["SSH_PASS"]
client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect("77.237.232.181", port=2222, username="root", password=password, timeout=40, allow_agent=False, look_for_keys=False)

def run(cmd, timeout=60):
    stdin, stdout, stderr = client.exec_command(cmd, timeout=timeout)
    out = stdout.read().decode("utf-8", "replace")
    err = stderr.read().decode("utf-8", "replace")
    print(out[-6000:])
    if err.strip():
        print("ERR", err[-1500:])

schema = "/home/adminanmkavps/web/bouslty.anmka.com/public_html/backend/prisma/schema.prisma"
run(f"python3 - << 'PY'\nfrom pathlib import Path\ntext=Path({schema!r}).read_text()\nstart=text.find('model User ')\nprint(text[start:start+1800])\nPY")
client.close()
