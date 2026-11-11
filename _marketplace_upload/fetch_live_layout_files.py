import os
from pathlib import Path

import paramiko


client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect("77.237.232.181", port=2222, username="root", password=os.environ["SSH_PASS"], timeout=40, allow_agent=False, look_for_keys=False)
sftp = client.open_sftp()
base = "/home/adminanmkavps/web/bouslty.anmka.com/public_html"
target = Path(__file__).resolve().parent / "live-current"
files = {
    f"{base}/components/layout/admin-layout.tsx": "admin-layout-component.tsx",
    f"{base}/components/layout/app-layout.tsx": "app-layout-component.tsx",
    f"{base}/app/admin/dashboard/page.tsx": "admin-dashboard-page.tsx",
    f"{base}/app/admin/notifications/page.tsx": "admin-notifications-page.tsx",
}
for remote, name in files.items():
    sftp.get(remote, str(target / name))
    print("FETCHED", name)
sftp.close()
client.close()
