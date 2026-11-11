import os
import sys
import paramiko

password = os.environ["SSH_PASS"]
client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect("77.237.232.181", port=2222, username="root", password=password, timeout=40, allow_agent=False, look_for_keys=False)
sftp = client.open_sftp()
local = r"E:\Animka_Projects\flutter-apps\osama-bouslty\_marketplace_upload"
admin = "/home/adminanmkavps/web/bouslty.anmka.com/public_html"
student = admin + "/arabic-educational-platform"
backend = admin + "/backend"

def run(cmd, timeout=900):
    print("\n===== " + cmd[:200], flush=True)
    stdin, stdout, stderr = client.exec_command(cmd, timeout=timeout)
    out = stdout.read().decode("utf-8", "replace")
    err = stderr.read().decode("utf-8", "replace")
    code = stdout.channel.recv_exit_status()
    if out:
        print(out[-5000:], flush=True)
    if err.strip():
        print("ERR", err[-2500:], flush=True)
    print("EXIT", code, flush=True)
    return code

uploads = [
    (os.path.join(local, "marketplace.service.js"), f"{backend}/src/modules/marketplace/marketplace.service.js"),
    (os.path.join(local, "marketplace.routes.js"), f"{backend}/src/modules/marketplace/marketplace.routes.js"),
    (os.path.join(local, "student", "marketplace-booking.tsx"), f"{student}/components/marketplace-booking.tsx"),
    (os.path.join(local, "student", "register-page.tsx"), f"{student}/app/register/page.tsx"),
    (os.path.join(local, "student", "app__instructors__page.tsx"), f"{student}/app/instructors/page.tsx"),
    (os.path.join(local, "student", "app__instructors__[id]__page.tsx"), f"{student}/app/instructors/[id]/page.tsx"),
    (os.path.join(local, "admin-marketplace-page.next.tsx"), f"{admin}/app/admin/marketplace/page.tsx"),
    (os.path.join(local, "web", "sidebar.tsx"), f"{admin}/components/layout/sidebar.tsx"),
]
for src, dest in uploads:
    print("PUT", dest, flush=True)
    sftp.put(src, dest)

patch = r'''
from pathlib import Path
p = Path("%s/prisma/schema.prisma")
text = p.read_text()
start = text.find("enum SessionBookingStatus")
print("anchor", start)
if start < 0:
    raise SystemExit("missing enum")
window = text[start:start+180]
print(window)
if "requested" not in window:
    text = text.replace(
        "enum SessionBookingStatus {\n  pending_payment",
        "enum SessionBookingStatus {\n  requested\n  pending_payment",
        1,
    )
    p.write_text(text)
    print("patched")
else:
    print("already")

# Marketplace categories must remain admin-driven. Older deployments already
# contain TrainerProfile, so the original bootstrap patch would otherwise skip
# these new columns.
if "categoryId             String?" not in text:
    text = text.replace(
        '  yearsExperience        Int?                        @map("years_experience")',
        '  yearsExperience        Int?                        @map("years_experience")\n'
        '  categoryId             String?                     @map("category_id")\n'
        '  subcategoryId          String?                     @map("subcategory_id")',
        1,
    )
    text = text.replace(
        '  @@index([isAcceptingBookings])',
        '  @@index([isAcceptingBookings])\n  @@index([categoryId])\n  @@index([subcategoryId])',
        1,
    )
    p.write_text(text)
    print("category columns patched")

if 'priceOptionsUsd    String?' not in text:
    updated = text.replace(
        '  defaultCurrency    String  @default("EGP") @map("default_currency") @db.VarChar(3)',
        '  defaultCurrency    String  @default("USD") @map("default_currency") @db.VarChar(3)\n'
        '  priceOptionsUsd    String? @map("price_options_usd") @db.Text',
        1,
    )
    if updated == text:
        updated = text.replace(
            '  defaultCurrency    String  @default("USD") @map("default_currency") @db.VarChar(3)',
            '  defaultCurrency    String  @default("USD") @map("default_currency") @db.VarChar(3)\n'
            '  priceOptionsUsd    String? @map("price_options_usd") @db.Text',
            1,
        )
    text = updated
    p.write_text(text)
    print("admin price options patched")
''' % backend
code = run("python3 - << 'PY'\n" + patch + "\nPY")
if code != 0:
    sys.exit(code)

# This project is self-hosted, not served by Vercel. Leaving the Vercel
# Analytics components in the root layout generates a 404 on every page.
analytics_patch = f'''\
from pathlib import Path
import re
p = Path("{student}/app/layout.tsx")
if p.exists():
    text = p.read_text()
    updated = re.sub(r'^import\\s+\\{{?\\s*(Analytics|SpeedInsights)\\s*\\}}?\\s+from\\s+["\\\']@vercel/[^"\\\']+["\\\'];?\\s*$', '', text, flags=re.M)
    updated = re.sub(r'<(Analytics|SpeedInsights)\\s*/>', '', updated)
    if updated != text:
        p.write_text(updated)
        print("removed unused Vercel analytics components")
    else:
        print("no Vercel analytics components found")
'''
code = run("python3 - << 'PY'\n" + analytics_patch + "\nPY")
if code != 0:
    sys.exit(code)

code = run(f"cd {backend} && npx prisma generate && npx prisma db push --skip-generate", timeout=180)
if code != 0:
    sys.exit(code)
run("pm2 restart bouslty-anmka-lms-backend --update-env && sleep 3 && curl -sS -o /dev/null -w 'api %{http_code}\\n' http://127.0.0.1:16821/api/trainers?per_page=1")

for cwd in (student, admin):
    code = run(f"cd {cwd} && npm run build:direct", timeout=1200)
    if code != 0:
        sys.exit(code)
run("pm2 restart bouslty-anmka-student bouslty-anmka-admin --update-env && sleep 5 && curl -sS -o /dev/null -w 'home %{http_code}\\n' https://bouslty.anmka.com/ && curl -sS -o /dev/null -w 'register %{http_code}\\n' https://bouslty.anmka.com/register")
client.close()
