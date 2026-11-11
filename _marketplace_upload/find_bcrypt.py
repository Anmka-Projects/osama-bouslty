import os, paramiko
password = os.environ["SSH_PASS"]
c = paramiko.SSHClient()
c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
c.connect("77.237.232.181", 2222, "root", password, timeout=30, allow_agent=False, look_for_keys=False)
cmd = "ls /home/adminanmkavps/web/bouslty.anmka.com/public_html/backend/node_modules | grep -i bcrypt; node -e \"console.log(require('bcrypt') ? 'bcrypt-ok' : 'no')\""
i,o,e = c.exec_command("cd /home/adminanmkavps/web/bouslty.anmka.com/public_html/backend && ls node_modules | grep -i -E 'bcrypt|argon'")
print(o.read().decode())
print(e.read().decode()[-300:])
c.close()
