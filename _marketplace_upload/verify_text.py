import os
import paramiko

password = os.environ["SSH_PASS"]
client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect("77.237.232.181", port=2222, username="root", password=password, timeout=40, allow_agent=False, look_for_keys=False)

def run(cmd, timeout=60):
    print("\n===== " + cmd[:220], flush=True)
    stdin, stdout, stderr = client.exec_command(cmd, timeout=timeout)
    out = stdout.read().decode("utf-8", "replace")
    err = stderr.read().decode("utf-8", "replace")
    print(out[-4000:], flush=True)
    if err.strip():
        print("ERR", err[-1500:], flush=True)

student = "/home/adminanmkavps/web/bouslty.anmka.com/public_html/arabic-educational-platform"
admin = "/home/adminanmkavps/web/bouslty.anmka.com/public_html"
run(f"grep -n 'احجز جلسة' {student}/components/navbar.tsx {student}/app/page.tsx {student}/app/instructors/page.tsx | head")
run(f"grep -R -l 'احجز جلسة' {student}/.next/static {student}/.next/server 2>/dev/null | head")
run(f"grep -R -l 'حجوزات الجلسات' {admin}/.next/server {admin}/components/layout/sidebar.tsx | head")
run(f"curl -sS http://127.0.0.1:16822/ | python3 -c \"import sys; t=sys.stdin.read(); print(len(t)); print('literal', t.count('احجز')); print('esc', t.count('062d062c0632'))\"")
client.close()
