import os, paramiko
c = paramiko.SSHClient()
c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
c.connect("77.237.232.181", port=2222, username="root", password=os.environ["SSH_PASS"], timeout=25, allow_agent=False, look_for_keys=False)
cmd = r"""
echo LOCAL16820 $(curl -sS -m 10 -o /dev/null -w '%{http_code}' http://127.0.0.1:16820/trainers.html)
echo LOCAL16822 $(curl -sS -m 10 -o /dev/null -w '%{http_code}' http://127.0.0.1:16822/trainers.html)
echo PUBLIC $(curl -sS -m 15 -D - -o /dev/null https://bouslty.anmka.com/trainers.html | head -n 20)
echo '--- nginx ---'
grep -n '16820\|16822\|16821\|proxy_pass\|location' /etc/nginx/conf.d/domains/bouslty.anmka.com.ssl.conf | head -80
"""
i,o,e = c.exec_command(cmd, timeout=30)
print(o.read().decode()[:6000])
print(e.read().decode()[:400])
c.close()
