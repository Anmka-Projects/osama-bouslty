import os, paramiko
c = paramiko.SSHClient()
c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
c.connect("77.237.232.181", port=2222, username="root", password=os.environ["SSH_PASS"], timeout=25, allow_agent=False, look_for_keys=False)
base = "/home/adminanmkavps/web/bouslty.anmka.com/public_html/arabic-educational-platform"

def run(cmd):
    print("\n====", cmd[:200])
    i,o,e = c.exec_command(cmd, timeout=25)
    print(o.read().decode()[:5000])

run(f"ls {base}/app | head -40")
run(f"ls {base}/components | head -40")
run(f"grep -Rln 'instructors\\|المدرب' {base}/app {base}/components --include='*.tsx' | head -20")
run(f"sed -n '1,40p' {base}/package.json")
c.close()
