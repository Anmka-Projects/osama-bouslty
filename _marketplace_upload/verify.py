import os, paramiko
c = paramiko.SSHClient()
c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
c.connect("77.237.232.181", port=2222, username="root", password=os.environ["SSH_PASS"], timeout=25, allow_agent=False, look_for_keys=False)

def run(cmd):
    print("\n====", cmd[:160])
    i,o,e = c.exec_command(cmd, timeout=30)
    print(o.read().decode()[:2000])
    err = e.read().decode()
    if err.strip():
        print("ERR", err[:500])

run("curl -sS -m 20 -o /dev/null -w '%{http_code}' https://bouslty.anmka.com/api/trainers?per_page=1")
run("curl -sS -m 20 -o /dev/null -w '%{http_code}' https://bouslty.anmka.com/trainers.html")
run("curl -sS -m 20 -o /dev/null -w '%{http_code}' https://bouslty.anmka.com/admin-marketplace.html")
run("tail -n 40 /home/adminanmkavps/web/bouslty.anmka.com/public_html/logs/pm2-backend-error.log")
c.close()
