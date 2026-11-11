import os
import paramiko
password = os.environ["SSH_PASS"]
client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect("77.237.232.181", port=2222, username="root", password=password, timeout=30, allow_agent=False, look_for_keys=False)
stdin, stdout, stderr = client.exec_command("curl -sSI https://bouslty.anmka.com/courses | head -n 20; echo ----; curl -sS https://bouslty.anmka.com/ | python3 -c \"import sys; t=sys.stdin.read(); print('courses_word', t.count('الدورات')); print('book', t.count('احجز جلسة'))\"")
print(stdout.read().decode("utf-8", "replace"))
print(stderr.read().decode("utf-8", "replace")[-500:])
client.close()
