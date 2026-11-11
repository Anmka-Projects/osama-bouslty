import os
import time
import paramiko
password = os.environ["SSH_PASS"]
client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect("77.237.232.181", port=2222, username="root", password=password, timeout=30, allow_agent=False, look_for_keys=False)
cmd = r"""
pm2 describe bouslty-anmka-student | grep -E 'status|restarts|error'
sleep 3
curl -sS -o /dev/null -w 'home %{http_code}\n' https://bouslty.anmka.com/
curl -sS -o /dev/null -w 'instructors %{http_code}\n' https://bouslty.anmka.com/instructors
python3 - << 'PY'
from pathlib import Path
p = Path("/home/adminanmkavps/web/bouslty.anmka.com/public_html/arabic-educational-platform/app/dashboard/page.tsx")
text = p.read_text()
for i,line in enumerate(text.splitlines(),1):
    if "دور" in line or "courses" in line:
        print(f"{i}:{line.strip()[:180]}")
PY
"""
stdin, stdout, stderr = client.exec_command(cmd)
print(stdout.read().decode("utf-8","replace"))
print(stderr.read().decode("utf-8","replace")[-400:])
client.close()
