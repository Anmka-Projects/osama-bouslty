import os, paramiko
c = paramiko.SSHClient()
c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
c.connect("77.237.232.181", port=2222, username="root", password=os.environ["SSH_PASS"], timeout=25, allow_agent=False, look_for_keys=False)
i,o,e = c.exec_command("pm2 restart bouslty-anmka-admin --update-env && sleep 4 && curl -sS -m 20 -o /dev/null -w '%{http_code}' http://127.0.0.1:16820/trainers.html && echo && curl -sS -m 20 -o /dev/null -w '%{http_code}' https://bouslty.anmka.com/trainers.html", timeout=40)
print(o.read().decode()[-1500:])
print(e.read().decode()[-800:])
c.close()
