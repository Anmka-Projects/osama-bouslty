import os
import paramiko
password = os.environ["SSH_PASS"]
client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect("77.237.232.181", port=2222, username="root", password=password, timeout=30, allow_agent=False, look_for_keys=False)
cmd = r"""
student=/home/adminanmkavps/web/bouslty.anmka.com/public_html/arabic-educational-platform
grep -R -n 'الدورات' $student/components $student/app --include='*.tsx' | head -40
echo ----LOC----
curl -sSI https://bouslty.anmka.com/courses | grep -i -E 'HTTP/|location|cache'
"""
stdin, stdout, stderr = client.exec_command(cmd)
print(stdout.read().decode('utf-8','replace'))
client.close()
