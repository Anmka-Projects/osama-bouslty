import os

import paramiko


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
base = "/home/adminanmkavps/web/bouslty.anmka.com/public_html"
commands = [
    f"find {base}/app -maxdepth 4 -type f -name 'layout.tsx' -print",
    f"grep -Rln 'Sidebar' {base}/app {base}/components --include='*.tsx' | head -50",
    f"find {base}/app/admin -maxdepth 2 -type f -name 'page.tsx' | sort | head -100",
]
for command in commands:
    stdin, stdout, stderr = client.exec_command(command, timeout=40)
    print(f"\n$ {command}\n{stdout.read().decode('utf-8', 'replace')}")
    error = stderr.read().decode("utf-8", "replace")
    if error.strip():
        print(error)
client.close()
