import os
import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect("77.237.232.181", port=2222, username="root", password=os.environ["SSH_PASS"], timeout=40, allow_agent=False, look_for_keys=False)
root = "/home/adminanmkavps/web/bouslty.anmka.com/public_html"
commands = [
    f"find {root}/backend/src -maxdepth 4 -type f \( -iname '*chat*' -o -iname '*upload*' \) -print",
    f"find {root}/arabic-educational-platform -maxdepth 5 -type f \( -path '*/lib/api*' -o -path '*/api/upload*' -o -iname '*chat*' \) -print | head -100",
    f"grep -R -l 'uploadMixed' {root}/backend/src --include='*.js' | head -30",
]
for command in commands:
    _, stdout, stderr = client.exec_command(command, timeout=60)
    print(stdout.read().decode("utf-8", "replace"))
    print(stderr.read().decode("utf-8", "replace"))
client.close()
