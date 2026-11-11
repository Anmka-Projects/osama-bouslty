import os
import paramiko

c = paramiko.SSHClient()
c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
c.connect(
    "77.237.232.181",
    port=2222,
    username="root",
    password=os.environ["SSH_PASS"],
    timeout=25,
    allow_agent=False,
    look_for_keys=False,
)
sftp = c.open_sftp()
base = "/home/adminanmkavps/web/bouslty.anmka.com/public_html"
local = r"E:\Animka_Projects\flutter-apps\osama-bouslty\_marketplace_upload\web"
os.makedirs(local, exist_ok=True)
for remote, name in [
    (f"{base}/components/navbar.tsx", "navbar.tsx"),
    (f"{base}/components/layout/sidebar.tsx", "sidebar.tsx"),
    (f"{base}/app/page.tsx", "home-page.tsx"),
]:
    sftp.get(remote, os.path.join(local, name))
    print("got", name)

def run(cmd):
    print("\n====", cmd[:180])
    stdin, stdout, stderr = c.exec_command(cmd, timeout=20)
    print(stdout.read().decode()[:4000])

run("ls /home/adminanmkavps/conf/web/bouslty.anmka.com/nginx.ssl.conf* ; echo '---'; wc -l /home/adminanmkavps/conf/web/bouslty.anmka.com/nginx.ssl.conf*")
sftp.close()
c.close()
