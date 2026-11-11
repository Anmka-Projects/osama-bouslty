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


def run(cmd, timeout=900):
    print("\n===== " + cmd[:300], flush=True)
    stdin, stdout, stderr = client.exec_command(cmd, timeout=timeout)
    out = stdout.read().decode("utf-8", "replace")
    err = stderr.read().decode("utf-8", "replace")
    code = stdout.channel.recv_exit_status()
    if out:
        print(out[-12000:], flush=True)
    if err.strip():
        print("ERR", err[-6000:], flush=True)
    print("EXIT", code, flush=True)
    return code, out, err


code, out, err = run("pm2 describe bouslty-anmka-student | grep -E 'exec cwd|status'")
student = None
for line in out.splitlines():
    if "exec cwd" in line:
        student = line.split("│")[-2].strip() if "│" in line else line.split()[-1]
if not student or not student.startswith("/"):
    print("student cwd missing", repr(out))
    sys.exit(1)
print("STUDENT", student, flush=True)

run(f"ls {student}/app/dashboard | head -40; echo ---; test -f {student}/app/dashboard/layout.tsx && echo HAS_DASH_LAYOUT || echo NO_DASH_LAYOUT; test -f {admin}/components/layout/sidebar.tsx && echo HAS_SIDEBAR; test -f {admin}/app/admin/layout.tsx && echo HAS_ADMIN_LAYOUT")

uploads = [
    (os.path.join(local, "student", "components__navbar.tsx"), f"{student}/components/navbar.tsx"),
    (os.path.join(local, "student", "app__page.tsx"), f"{student}/app/page.tsx"),
    (os.path.join(local, "student", "app__instructors__page.tsx"), f"{student}/app/instructors/page.tsx"),
    (os.path.join(local, "student", "app__instructors__[id]__page.tsx"), f"{student}/app/instructors/[id]/page.tsx"),
    (os.path.join(local, "student", "marketplace-booking.tsx"), f"{student}/components/marketplace-booking.tsx"),
    (os.path.join(local, "student", "dashboard-bookings-page.tsx"), f"{student}/app/dashboard/bookings/page.tsx"),
    (os.path.join(local, "web", "sidebar.tsx"), f"{admin}/components/layout/sidebar.tsx"),
    (os.path.join(local, "admin-marketplace-page.next.tsx"), f"{admin}/app/admin/marketplace/page.tsx"),
    (os.path.join(local, "marketplace.service.js"), f"{admin}/backend/src/modules/marketplace/marketplace.service.js"),
]
run(f"mkdir -p {student}/app/dashboard/bookings {admin}/app/admin/marketplace")
for src, dest in uploads:
    print("PUT", dest, flush=True)
    sftp.put(src, dest)

run(f"cd {admin}/backend && pm2 restart bouslty-anmka-lms-backend --update-env && sleep 2 && curl -sS 'http://127.0.0.1:16821/api/trainers?per_page=1' | head -c 400")

stamp = "$(date +%Y%m%d%H%M%S)"
build_student = f"""
set -e
cd {student}
if [ -d .next ]; then rm -rf /tmp/bouslty-student-next && cp -a .next /tmp/bouslty-student-next; fi
npm run build:direct
"""
code, out, err = run(build_student, timeout=1200)
if code != 0:
    run(f"rm -rf {student}/.next && cp -a /tmp/bouslty-student-next {student}/.next && echo RESTORED_STUDENT")
    sys.exit(code)

build_admin = f"""
set -e
cd {admin}
if [ -d .next ]; then rm -rf /tmp/bouslty-admin-next && cp -a .next /tmp/bouslty-admin-next; fi
npm run build:direct
"""
code, out, err = run(build_admin, timeout=1200)
if code != 0:
    run(f"rm -rf {admin}/.next && cp -a /tmp/bouslty-admin-next {admin}/.next && echo RESTORED_ADMIN")
    sys.exit(code)

run("pm2 restart bouslty-anmka-student bouslty-anmka-admin --update-env && sleep 4 && curl -sS -o /dev/null -w 'home %{http_code}\\n' https://bouslty.anmka.com/ && curl -sS https://bouslty.anmka.com/ | grep -o 'احجز جلسة' | head -5 && curl -sS -o /dev/null -w 'instructors %{http_code}\\n' https://bouslty.anmka.com/instructors && curl -sS -o /dev/null -w 'bookings %{http_code}\\n' https://bouslty.anmka.com/dashboard/bookings && curl -sS -o /dev/null -w 'admin %{http_code}\\n' https://bouslty.anmka.com/admin/marketplace")
client.close()
