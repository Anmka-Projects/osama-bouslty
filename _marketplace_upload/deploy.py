import os
import paramiko

password = os.environ["SSH_PASS"]
client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect("77.237.232.181", port=2222, username="root", password=password, timeout=30, allow_agent=False, look_for_keys=False)
sftp = client.open_sftp()
base = "/home/adminanmkavps/web/bouslty.anmka.com/public_html"
local = r"E:\Animka_Projects\flutter-apps\osama-bouslty\_marketplace_upload"


def run(cmd, timeout=180):
    print("\n===== " + cmd[:220])
    stdin, stdout, stderr = client.exec_command(cmd, timeout=timeout)
    out = stdout.read().decode("utf-8", "replace")
    err = stderr.read().decode("utf-8", "replace")
    if out:
        print(out[-8000:])
    if err.strip():
        print("ERR", err[-4000:])
    return out, err


run(f"mkdir -p {base}/backend/src/modules/marketplace {base}/public {base}/app/trainers {base}/app/admin/marketplace")
sftp.put(os.path.join(local, "marketplace.service.js"), f"{base}/backend/src/modules/marketplace/marketplace.service.js")
sftp.put(os.path.join(local, "marketplace.routes.js"), f"{base}/backend/src/modules/marketplace/marketplace.routes.js")
sftp.put(os.path.join(local, "web", "trainers.html"), f"{base}/public/trainers.html")
sftp.put(os.path.join(local, "web", "admin-marketplace.html"), f"{base}/public/admin-marketplace.html")
sftp.put(os.path.join(local, "web", "trainers-page.tsx"), f"{base}/app/trainers/page.tsx")
sftp.put(os.path.join(local, "admin-marketplace-page.next.tsx"), f"{base}/app/admin/marketplace/page.tsx")

patch = r'''
python3 - << 'PY'
from pathlib import Path
base = Path("/home/adminanmkavps/web/bouslty.anmka.com/public_html")
schema = base / "backend/prisma/schema.prisma"
text = schema.read_text()
if "model TrainerProfile" not in text:
    needle = "  activationCodeRedemptions  ActivationCodeRedemption[]\n"
    extra = needle + """  trainerProfile             TrainerProfile?
  studentSessionBookings     SessionBooking[]            @relation(\"StudentSessionBookings\")
  trainerSessionBookings     SessionBooking[]            @relation(\"TrainerSessionBookings\")
  bookingReviewsWritten      BookingReview[]             @relation(\"BookingReviewsWritten\")
  payoutRequests             PayoutRequest[]
  earningLedger              TrainerEarningLedger[]
"""
    if needle not in text:
        raise SystemExit("schema anchor missing")
    fragment = Path("/tmp/schema.fragment.prisma").read_text()
    text = text.replace(needle, extra, 1).rstrip() + "\n\n" + fragment + "\n"
    schema.write_text(text)
    print("schema patched")
else:
    print("schema already patched")

routes = base / "backend/src/routes.js"
rtext = routes.read_text()
if "marketplace.routes" not in rtext:
    rtext = rtext.replace(
        "import adminInboxRoutes from './modules/adminInbox/adminInbox.routes.js';",
        "import adminInboxRoutes from './modules/adminInbox/adminInbox.routes.js';\nimport marketplaceRoutes from './modules/marketplace/marketplace.routes.js';",
    )
    rtext = rtext.replace("// API info endpoint", "router.use(marketplaceRoutes);\n\n// API info endpoint")
    routes.write_text(rtext)
    print("routes patched")
else:
    print("routes already patched")

sidebar = base / "components/layout/sidebar.tsx"
if sidebar.exists():
    s = sidebar.read_text()
    if "/admin/marketplace" not in s and "admin-marketplace.html" not in s:
        needle = 'href: "/admin/enrollment-requests"'
        if needle in s:
            s = s.replace(needle, 'href: "/admin-marketplace.html"', 1)
            # keep original enrollment link by inserting a new item before it instead
            print("sidebar needle found, manual insert skipped to avoid removing enrollment")
        print("SIDEBAR_HEAD")
        for i,line in enumerate(s.splitlines()):
            if "enrollment" in line or "href:" in line and "admin" in line:
                if "enrollment" in line or "حجوز" in line:
                    print(i, line[:180])
    else:
        print("sidebar already linked")
else:
    print("no sidebar")
PY
'''
sftp.put(os.path.join(local, "schema.fragment.prisma"), "/tmp/schema.fragment.prisma")
run(patch)
run(f"cd {base}/backend && npx prisma generate && npx prisma db push --skip-generate", timeout=240)
run("pm2 restart bouslty-anmka-lms-backend --update-env && sleep 2 && pm2 describe bouslty-anmka-lms-backend | sed -n '1,25p'")
run("curl -sS -m 20 http://127.0.0.1:16821/api/trainers?per_page=2 | head -c 1500")
sftp.close()
client.close()
print("DEPLOY_DONE")
