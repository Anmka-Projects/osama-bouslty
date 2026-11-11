import os, paramiko
c = paramiko.SSHClient()
c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
c.connect("77.237.232.181", port=2222, username="root", password=os.environ["SSH_PASS"], timeout=20, allow_agent=False, look_for_keys=False)
i,o,e = c.exec_command("wc -l /etc/nginx/conf.d/domains/bouslty.anmka.com.ssl.conf; sed -n '1,160p' /etc/nginx/conf.d/domains/bouslty.anmka.com.ssl.conf", timeout=20)
print(o.read().decode())
c.close()
