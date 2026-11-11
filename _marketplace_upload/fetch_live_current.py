import os
from pathlib import Path

import paramiko


password = os.environ["SSH_PASS"]
host = "77.237.232.181"
port = 2222
root = Path(__file__).resolve().parent / "live-current"
root.mkdir(parents=True, exist_ok=True)

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(
    host,
    port=port,
    username="root",
    password=password,
    timeout=40,
    allow_agent=False,
    look_for_keys=False,
)
sftp = client.open_sftp()

admin = "/home/adminanmkavps/web/bouslty.anmka.com/public_html"
backend = f"{admin}/backend"

stdin, stdout, stderr = client.exec_command(
    "pm2 describe bouslty-anmka-student | grep 'exec cwd'", timeout=30
)
output = stdout.read().decode("utf-8", "replace")
student = None
for line in output.splitlines():
    if "exec cwd" in line:
        student = line.split("│")[-2].strip() if "│" in line else line.split()[-1]
if not student:
    raise RuntimeError(f"Student cwd not found: {output}")

files = {
    f"{student}/app/instructors/page.tsx": "student-instructors-page.tsx",
    f"{admin}/components/layout/sidebar.tsx": "admin-sidebar.tsx",
    f"{admin}/app/admin/marketplace/page.tsx": "admin-marketplace-page.tsx",
    f"{admin}/app/admin/tutor-controls/page.tsx": "admin-tutor-controls-page.tsx",
    f"{admin}/app/admin/layout.tsx": "admin-layout.tsx",
    f"{backend}/src/modules/marketplace/marketplace.service.js": "marketplace.service.js",
    f"{backend}/src/modules/marketplace/marketplace.routes.js": "marketplace.routes.js",
    f"{backend}/prisma/schema.prisma": "schema.prisma",
}

for remote, local_name in files.items():
    try:
        destination = root / local_name
        sftp.get(remote, str(destination))
        print(f"FETCHED {local_name} {destination.stat().st_size}")
    except FileNotFoundError:
        print(f"MISSING {remote}")

(root / "student-cwd.txt").write_text(student, encoding="utf-8")
sftp.close()
client.close()
