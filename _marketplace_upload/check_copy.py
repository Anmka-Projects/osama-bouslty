import os
import paramiko
password = os.environ["SSH_PASS"]
client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect("77.237.232.181", port=2222, username="root", password=password, timeout=30, allow_agent=False, look_for_keys=False)
cmd = r"""
student=/home/adminanmkavps/web/bouslty.anmka.com/public_html/arabic-educational-platform
grep -n 'الدورات' $student/components/navbar.tsx $student/components/footer.tsx $student/app/page.tsx $student/components/app/mobile-bottom-nav.tsx | head -40
echo ----PAGE----
head -5 $student/app/courses/page.tsx
echo ----HTML----
curl -sS https://bouslty.anmka.com/courses | python3 -c "import sys; t=sys.stdin.read(); print(len(t)); print('redirect', 'instructors' in t); print('courses title', 'الدورات' in t)"
"""
stdin, stdout, stderr = client.exec_command(cmd)
print(stdout.read().decode('utf-8','replace'))
print(stderr.read().decode('utf-8','replace')[-400:])
client.close()
