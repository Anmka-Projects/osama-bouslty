import os
from pathlib import Path

import paramiko


output = Path(__file__).resolve().parent / "student-features-current"
output.mkdir(parents=True, exist_ok=True)
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

_, stdout, _ = client.exec_command("pm2 describe bouslty-anmka-student | grep 'exec cwd'", timeout=30)
raw = stdout.read().decode("utf-8", "replace")
student = next(
    (line.split("│")[-2].strip() for line in raw.splitlines() if "exec cwd" in line),
    None,
)
if not student:
    raise RuntimeError("Student cwd not found")

admin = "/home/adminanmkavps/web/bouslty.anmka.com/public_html"
backend = f"{admin}/backend"
files = {
    f"{student}/app/instructors/[id]/page.tsx": "instructor-detail-page.tsx",
    f"{student}/components/marketplace-booking.tsx": "marketplace-booking.tsx",
    f"{student}/app/dashboard/bookings/page.tsx": "dashboard-bookings-page.tsx",
    f"{student}/app/dashboard/chat/page.tsx": "dashboard-chat-page.tsx",
    f"{student}/app/dashboard/chat/[id]/page.tsx": "dashboard-chat-detail-page.tsx",
    f"{student}/app/dashboard/layout.tsx": "dashboard-layout.tsx",
    f"{student}/app/dashboard/page.tsx": "dashboard-page.tsx",
    f"{backend}/src/modules/chat/chat.routes.js": "chat.routes.js",
    f"{backend}/src/modules/chat/chat.controller.js": "chat.controller.js",
    f"{backend}/src/modules/chat/chat.service.js": "chat.service.js",
    f"{backend}/src/modules/chat/chat.schema.js": "chat.schema.js",
    f"{backend}/src/shared/middleware/upload.middleware.js": "upload.middleware.js",
    f"{backend}/src/routes.js": "backend-routes.js",
    f"{student}/lib/api.ts": "student-api.ts",
    f"{backend}/src/modules/upload/upload.routes.js": "upload.routes.js",
    f"{backend}/src/modules/upload/upload.controller.js": "upload.controller.js",
    f"{backend}/src/modules/upload/upload.service.js": "upload.service.js",
}

sftp = client.open_sftp()
try:
    for remote, name in files.items():
        try:
            sftp.get(remote, str(output / name))
            print(f"FETCHED {name}")
        except FileNotFoundError:
            print(f"MISSING {remote}")
finally:
    sftp.close()
    client.close()

(output / "student-cwd.txt").write_text(student, encoding="utf-8")
