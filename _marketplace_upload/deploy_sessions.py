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


def run(cmd, timeout=900):
    print("\n===== " + cmd[:240], flush=True)
    stdin, stdout, stderr = client.exec_command(cmd, timeout=timeout)
    out = stdout.read().decode("utf-8", "replace")
    err = stderr.read().decode("utf-8", "replace")
    code = stdout.channel.recv_exit_status()
    if out:
        print(out[-8000:], flush=True)
    if err.strip():
        print("ERR", err[-3000:], flush=True)
    print("EXIT", code, flush=True)
    return code


uploads = [
    (os.path.join(local, "student", "components__navbar.tsx"), f"{student}/components/navbar.tsx"),
    (os.path.join(local, "student", "components__footer.tsx"), f"{student}/components/footer.tsx"),
    (os.path.join(local, "student", "app__page.tsx"), f"{student}/app/page.tsx"),
    (os.path.join(local, "student", "app__instructors__page.tsx"), f"{student}/app/instructors/page.tsx"),
    (os.path.join(local, "student", "app__instructors__[id]__page.tsx"), f"{student}/app/instructors/[id]/page.tsx"),
    (os.path.join(local, "student", "courses-redirect.tsx"), f"{student}/app/courses/page.tsx"),
    (os.path.join(local, "student", "courses-redirect.tsx"), f"{student}/app/courses/[id]/page.tsx"),
    (os.path.join(local, "web", "sidebar.tsx"), f"{admin}/components/layout/sidebar.tsx"),
]
for src, dest in uploads:
    print("PUT", dest, flush=True)
    sftp.put(src, dest)

patch = f"""
python3 - << 'PY'
from pathlib import Path
p = Path("{student}/components/app/mobile-bottom-nav.tsx")
text = p.read_text()
updated = text.replace('href: "/courses"', 'href: "/instructors"').replace("href: '/courses'", "href: '/instructors'")
updated = updated.replace('label: "الدورات"', 'label: "احجز جلسة"').replace(">الدورات<", ">احجز جلسة<")
updated = updated.replace("الدورات التدريبية", "احجز جلسة")
if updated != text:
    p.write_text(updated)
    print("patched mobile nav")
else:
    print("mobile nav has no course link")
print("courses mentions", updated.count("courses"))
PY
"""
run(patch)

code = run(f"""
set -e
cd {student}
if [ -d .next ]; then rm -rf /tmp/bouslty-student-next && cp -a .next /tmp/bouslty-student-next; fi
npm run build:direct
""", timeout=1200)
if code != 0:
    run(f"rm -rf {student}/.next && cp -a /tmp/bouslty-student-next {student}/.next && echo RESTORED_STUDENT")
    sys.exit(code)

code = run(f"""
set -e
cd {admin}
if [ -d .next ]; then rm -rf /tmp/bouslty-admin-next && cp -a .next /tmp/bouslty-admin-next; fi
npm run build:direct
""", timeout=1200)
if code != 0:
    run(f"rm -rf {admin}/.next && cp -a /tmp/bouslty-admin-next {admin}/.next && echo RESTORED_ADMIN")
    sys.exit(code)

run("pm2 restart bouslty-anmka-student bouslty-anmka-admin --update-env")
run("curl -sS -o /dev/null -w 'home %{http_code}\\n' https://bouslty.anmka.com/ && curl -sS -o /dev/null -w 'courses %{http_code} redirect %{redirect_url}\\n' https://bouslty.anmka.com/courses && curl -sS -o /dev/null -w 'instructors %{http_code}\\n' https://bouslty.anmka.com/instructors")
client.close()
