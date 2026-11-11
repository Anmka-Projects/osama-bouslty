import os, paramiko
c = paramiko.SSHClient()
c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
c.connect("77.237.232.181", port=2222, username="root", password=os.environ["SSH_PASS"], timeout=25, allow_agent=False, look_for_keys=False)
base = "/home/adminanmkavps/web/bouslty.anmka.com/public_html"
cmd = f"cp {base}/public/trainers.html {base}/trainers.html && cp {base}/public/admin-marketplace.html {base}/marketplace-admin.html && curl -sS -m 15 -o /dev/null -w 'trainers %{{http_code}}\\n' https://bouslty.anmka.com/trainers.html && curl -sS -m 15 -o /dev/null -w 'admin %{{http_code}}\\n' https://bouslty.anmka.com/marketplace-admin.html"
i,o,e = c.exec_command(cmd, timeout=30)
print(o.read().decode())
print(e.read().decode()[:400])
c.close()
