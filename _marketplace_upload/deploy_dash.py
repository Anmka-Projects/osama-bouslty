import os
import sys
import paramiko

password = os.environ["SSH_PASS"]
client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect("77.237.232.181", port=2222, username="root", password=password, timeout=40, allow_agent=False, look_for_keys=False)
student = "/home/adminanmkavps/web/bouslty.anmka.com/public_html/arabic-educational-platform"

def run(cmd, timeout=900):
    stdin, stdout, stderr = client.exec_command(cmd, timeout=timeout)
    out = stdout.read().decode("utf-8", "replace")
    err = stderr.read().decode("utf-8", "replace")
    code = stdout.channel.recv_exit_status()
    print(out[-2500:])
    if err.strip():
        print("ERR", err[-800:])
    print("EXIT", code)
    return code

code = run(f"""python3 - << 'PY'
from pathlib import Path
p = Path("{student}/app/dashboard/page.tsx")
text = p.read_text()
text = text.replace('active="courses"', 'active="bookings"')
text = text.replace('href="/courses"', 'href="/instructors"')
text = text.replace("اكتشف دورات جديدة", "احجز جلسة")
text = text.replace("لم تسجل في أي دورة بعد", "ابدأ بحجز جلسة مع مدرب")
p.write_text(text)
print("remaining course hrefs", text.count('href="/courses"'))
PY
cd {student} && npm run build:direct
""")
if code != 0:
    sys.exit(code)
run("pm2 restart bouslty-anmka-student --update-env && sleep 4 && curl -sS -o /dev/null -w 'home %{http_code}\\n' https://bouslty.anmka.com/ && curl -sS -o /dev/null -w 'dash %{http_code}\\n' https://bouslty.anmka.com/dashboard")
client.close()
