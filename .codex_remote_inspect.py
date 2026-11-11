import json
import os
import paramiko


host = os.environ["TAALLAM_SSH_HOST"]
port = int(os.environ.get("TAALLAM_SSH_PORT", "22"))
username = os.environ["TAALLAM_SSH_USER"]
password = os.environ["TAALLAM_SSH_PASSWORD"]

default_commands = [
    "pwd",
    "uname -a",
    "find /var/www /opt /srv -maxdepth 3 -type f \\( -name package.json -o -name docker-compose.yml -o -name nginx.conf -o -name .env \\) 2>/dev/null | head -100",
    "find /var/www /opt /srv -maxdepth 2 -type d 2>/dev/null | head -150",
    "nginx -T 2>/dev/null | grep -nE 'server_name|root |proxy_pass|location ' | head -250",
    "ps -eo pid,cmd --sort=-pid | grep -E 'node|pm2|docker|nginx' | grep -v grep | head -100",
    "command -v node; node --version 2>/dev/null; command -v npm; npm --version 2>/dev/null; command -v pnpm; command -v yarn; command -v docker; command -v pm2",
]
commands_text = os.environ.get("TAALLAM_SSH_COMMANDS")
commands = commands_text.split("|||REMOTE_COMMAND|||") if commands_text else default_commands

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(host, port=port, username=username, password=password, timeout=20)
try:
    for command in commands:
        print(f"\n### {command}")
        _, stdout, stderr = client.exec_command(command, timeout=30)
        print(stdout.read().decode("utf-8", "replace"))
        error = stderr.read().decode("utf-8", "replace")
        if error:
            print("STDERR:", error)
finally:
    client.close()
