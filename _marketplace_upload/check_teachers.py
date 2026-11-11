import os, paramiko
password = os.environ["SSH_PASS"]
c = paramiko.SSHClient()
c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
c.connect("77.237.232.181", 2222, "root", password, timeout=30, allow_agent=False, look_for_keys=False)
cmd = "curl -sS 'http://127.0.0.1:16821/api/teachers?per_page=20' | python3 -c \"import sys,json; d=json.load(sys.stdin); data=d.get('data') or {}; rows=data.get('teachers') or data.get('data') or []; print(type(data), list(data)[:8] if isinstance(data, dict) else 'list'); print('n', len(rows) if isinstance(rows, list) else rows)\""
i,o,e = c.exec_command(cmd)
print(o.read().decode("utf-8","replace")[:2000])
print(e.read().decode()[-400:])
c.close()
