import os, paramiko
c = paramiko.SSHClient()
c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
c.connect("77.237.232.181", port=2222, username="root", password=os.environ["SSH_PASS"], timeout=25, allow_agent=False, look_for_keys=False)
cmd = "grep -n 'proxy_pass\\|location ' /home/adminanmkavps/conf/web/bouslty.anmka.com/nginx.ssl.conf_routing | head -80"
i,o,e = c.exec_command(cmd, timeout=20)
print(o.read().decode())
c.close()
