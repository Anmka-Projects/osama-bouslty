import os
import paramiko

password = os.environ["SSH_PASS"]
client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect("77.237.232.181", port=2222, username="root", password=password, timeout=40, allow_agent=False, look_for_keys=False)

def run(cmd, timeout=60):
    print("\n===== " + cmd[:240], flush=True)
    stdin, stdout, stderr = client.exec_command(cmd, timeout=timeout)
    out = stdout.read().decode("utf-8", "replace")
    err = stderr.read().decode("utf-8", "replace")
    print(out[-5000:], flush=True)
    if err.strip():
        print("ERR", err[-2500:], flush=True)
    print("EXIT", stdout.channel.recv_exit_status(), flush=True)

run("pm2 describe bouslty-anmka-lms-backend | grep -E 'status|restarts|unstable|error' ; curl -sS -m 8 -o /tmp/trainers.json -w 'api %{http_code}\\n' http://127.0.0.1:16821/api/trainers?per_page=1 ; python3 -c \"import json; d=json.load(open('/tmp/trainers.json')); print(d.get('success'), (d.get('data') or {}).get('pagination') or list((d.get('data') or {}).keys())[:6])\"")
run("curl -sS -m 15 https://bouslty.anmka.com/ | python3 -c \"import sys; t=sys.stdin.read(); print('home_len', len(t)); print('book_cta', t.count('احجز جلسة')); print('old_title', t.count('المدرسون')); print('session_with', 'احجز جلسة مع مدرب' in t)\"")
run("curl -sS -m 15 https://bouslty.anmka.com/instructors | python3 -c \"import sys; t=sys.stdin.read(); print('instructors_len', len(t)); print('cta', t.count('احجز جلسة'))\"")
run("curl -sS -m 15 -D - -o /dev/null https://bouslty.anmka.com/admin/marketplace | head -n 15")
run("pm2 logs bouslty-anmka-lms-backend --lines 30 --nostream")
client.close()
