import os
import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(
    "77.237.232.181",
    port=2222,
    username="root",
    password=os.environ["SSH_PASS"],
    timeout=40,
    allow_agent=False,
    look_for_keys=False,
)
commands = [
    "grep -RIl 'server_name.*bouslty\\.anmka\\.com' /etc/nginx 2>/dev/null | head -20",
    "for f in $(grep -RIl 'server_name.*bouslty\\.anmka\\.com' /etc/nginx 2>/dev/null); do echo ===$f; sed -n '1,260p' $f; done",
    "for f in /home/adminanmkavps/conf/web/bouslty.anmka.com/nginx.ssl.conf_* /home/adminanmkavps/conf/web/bouslty.anmka.com/nginx.conf_*; do test -f $f || continue; echo ===$f; cat $f; done",
    "pm2 describe bouslty-anmka-student | grep -E 'exec cwd|script args|script path|status|port'",
    "ss -ltnp | grep -E 'node|:3000|:3001' | tail -30",
]
for command in commands:
    _, stdout, stderr = client.exec_command(command, timeout=60)
    print(stdout.read().decode("utf-8", "replace"))
    print(stderr.read().decode("utf-8", "replace"))
client.close()
