import os, paramiko
c = paramiko.SSHClient()
c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
c.connect("77.237.232.181", port=2222, username="root", password=os.environ["SSH_PASS"], timeout=25, allow_agent=False, look_for_keys=False)
sftp = c.open_sftp()
base = "/home/adminanmkavps/web/bouslty.anmka.com/public_html"
local = r"E:\Animka_Projects\flutter-apps\osama-bouslty\_marketplace_upload\web"
sftp.get(f"{base}/app/instructors/page.tsx", os.path.join(local, "instructors-page.tsx"))
print("instructors", os.path.getsize(os.path.join(local, "instructors-page.tsx")))
# landing component path
stdin, stdout, stderr = c.exec_command(f"ls {base}/components/landing | head -30", timeout=20)
print(stdout.read().decode())
sftp.close()
c.close()
