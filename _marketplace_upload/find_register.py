import os, paramiko
password = os.environ["SSH_PASS"]
c = paramiko.SSHClient()
c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
c.connect("77.237.232.181", 2222, "root", password, timeout=30, allow_agent=False, look_for_keys=False)
cmd = r"""grep -n -E "role|register" /home/adminanmkavps/web/bouslty.anmka.com/public_html/arabic-educational-platform/app/register/page.tsx | head -40"""
i,o,e = c.exec_command(cmd)
print(o.read().decode("utf-8","replace"))
print(e.read().decode()[-300:])
c.close()
