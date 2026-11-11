import os
import paramiko

password = os.environ["SSH_PASS"]
client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect("77.237.232.181", port=2222, username="root", password=password, timeout=40, allow_agent=False, look_for_keys=False)
sftp = client.open_sftp()
remote = "/home/adminanmkavps/web/bouslty.anmka.com/public_html/backend/seed-demo-trainers.mjs"
sftp.put(r"E:\Animka_Projects\flutter-apps\osama-bouslty\_marketplace_upload\seed-demo-trainers.mjs", remote)
backend = "/home/adminanmkavps/web/bouslty.anmka.com/public_html/backend"
cmd = f"cd {backend} && node {remote}; rm -f {remote}; curl -sS 'http://127.0.0.1:16821/api/trainers?per_page=10' | python3 -c \"import sys,json; d=json.load(sys.stdin); rows=(d.get('data') or {{}}).get('trainers') or []; print('count', len(rows));\n[print(r.get('display_name'), r.get('starting_price'), r.get('headline'), r.get('is_accepting_bookings')) for r in rows]\""
stdin, stdout, stderr = client.exec_command(cmd, timeout=120)
print(stdout.read().decode("utf-8", "replace")[-4000:])
err = stderr.read().decode("utf-8", "replace")
if err.strip():
    print("ERR", err[-2500:])
print("EXIT", stdout.channel.recv_exit_status())
client.close()
