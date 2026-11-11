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
base = "/home/adminanmkavps/web/bouslty.anmka.com/public_html"


def run(cmd, timeout=30):
    print("\n====", cmd[:220])
    stdin, stdout, stderr = c.exec_command(cmd, timeout=timeout)
    print(stdout.read().decode("utf-8", "replace")[:8000])
    err = stderr.read().decode("utf-8", "replace")
    if err.strip():
        print("ERR", err[:500])


run(f"ls {base}/components | head -40")
run(f"grep -Rln 'المدربين\\|instructors\\|href: .*/courses' {base}/components {base}/app --include='*.tsx' | head -30")
run(f"ls {base}/app/admin | head -40")
run(f"grep -n 'href:' {base}/components/layout/sidebar.tsx | head -50")
run(f"sed -n '1,120p' {base}/package.json")
c.close()
