import os, paramiko
c = paramiko.SSHClient()
c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
c.connect("77.237.232.181", port=2222, username="root", password=os.environ["SSH_PASS"], timeout=25, allow_agent=False, look_for_keys=False)
sftp = c.open_sftp()
base = "/home/adminanmkavps/web/bouslty.anmka.com/public_html/arabic-educational-platform"
local = r"E:\Animka_Projects\flutter-apps\osama-bouslty\_marketplace_upload\student"
os.makedirs(local, exist_ok=True)
files = [
    "components/navbar.tsx",
    "app/page.tsx",
    "app/instructors/page.tsx",
    "app/instructors/[id]/page.tsx",
    "components/footer.tsx",
]
for rel in files:
    name = rel.replace("/", "__")
    sftp.get(f"{base}/{rel}", os.path.join(local, name))
    print(name, os.path.getsize(os.path.join(local, name)))
sftp.close()
c.close()
