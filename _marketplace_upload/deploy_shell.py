import os
import sys
import paramiko

password = os.environ["SSH_PASS"]
client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect("77.237.232.181", port=2222, username="root", password=password, timeout=40, allow_agent=False, look_for_keys=False)
sftp = client.open_sftp()
student = "/home/adminanmkavps/web/bouslty.anmka.com/public_html/arabic-educational-platform"
local = r"E:\Animka_Projects\flutter-apps\osama-bouslty\_marketplace_upload\student\app-shell.tsx"
sftp.put(local, f"{student}/components/app/app-shell.tsx")

def run(cmd, timeout=900):
    print("\n===== " + cmd[:180], flush=True)
    stdin, stdout, stderr = client.exec_command(cmd, timeout=timeout)
    out = stdout.read().decode("utf-8", "replace")
    err = stderr.read().decode("utf-8", "replace")
    code = stdout.channel.recv_exit_status()
    if out:
        print(out[-4000:], flush=True)
    if err.strip():
        print("ERR", err[-1500:], flush=True)
    print("EXIT", code, flush=True)
    return code

run(f"""python3 - << 'PY'
from pathlib import Path
p = Path("{student}/app/dashboard/page.tsx")
text = p.read_text()
text = text.replace("ابدأ رحلة التعلم الآن واكتشف مئات الدورات المتخصصة", "اختار مدرب واحجز جلسة واحدة أو باقة جلسات")
text = text.replace('<Link href="/courses"><Button className="rounded-full px-8">تصفح الدورات</Button></Link>', '<Link href="/instructors"><Button className="rounded-full px-8">احجز جلسة</Button></Link>')
p.write_text(text)
print("dashboard patched", "تصفح الدورات" in text)
PY""")

code = run(f"""
set -e
cd {student}
npm run build:direct
""", timeout=1200)
if code != 0:
    sys.exit(code)
run("pm2 restart bouslty-anmka-student --update-env && curl -sSI https://bouslty.anmka.com/ | head -n 8")
client.close()
