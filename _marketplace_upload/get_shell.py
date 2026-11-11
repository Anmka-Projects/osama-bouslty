import os
import paramiko
password = os.environ["SSH_PASS"]
client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect("77.237.232.181", port=2222, username="root", password=password, timeout=30, allow_agent=False, look_for_keys=False)
sftp = client.open_sftp()
remote = "/home/adminanmkavps/web/bouslty.anmka.com/public_html/arabic-educational-platform/components/app/app-shell.tsx"
local = r"E:\Animka_Projects\flutter-apps\osama-bouslty\_marketplace_upload\student\app-shell.tsx"
sftp.get(remote, local)
print("got", os.path.getsize(local))
client.close()
