import os, paramiko
c = paramiko.SSHClient()
c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
c.connect("77.237.232.181", port=2222, username="root", password=os.environ["SSH_PASS"], timeout=25, allow_agent=False, look_for_keys=False)

def run(cmd):
    print("\n====", cmd[:200])
    i,o,e = c.exec_command(cmd, timeout=25)
    print(o.read().decode()[:2500])
    err=e.read().decode()
    if err.strip():
        print("ERR", err[:400])

base="/home/adminanmkavps/web/bouslty.anmka.com/public_html"
run(f"ls -l {base}/public/trainers.html {base}/public/admin-marketplace.html")
run("curl -sS -m 15 -o /dev/null -w '%{http_code} %{redirect_url}' http://127.0.0.1:16820/trainers.html")
run(f"sed -n '1,80p' {base}/middleware.ts")
c.close()
