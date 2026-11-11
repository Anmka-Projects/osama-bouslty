import os, paramiko
password = os.environ["SSH_PASS"]
c = paramiko.SSHClient()
c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
c.connect("77.237.232.181", 2222, "root", password, timeout=30, allow_agent=False, look_for_keys=False)
sftp = c.open_sftp()
sftp.get(
    "/home/adminanmkavps/web/bouslty.anmka.com/public_html/arabic-educational-platform/app/register/page.tsx",
    r"E:\Animka_Projects\flutter-apps\osama-bouslty\_marketplace_upload\student\register-page.tsx",
)
print("ok")
c.close()
