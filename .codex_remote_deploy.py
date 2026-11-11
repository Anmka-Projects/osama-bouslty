import os
import posixpath
import paramiko


host = os.environ["TAALLAM_SSH_HOST"]
port = int(os.environ.get("TAALLAM_SSH_PORT", "22"))
username = os.environ["TAALLAM_SSH_USER"]
password = os.environ["TAALLAM_SSH_PASSWORD"]
local_root = os.path.abspath("admin-dashboard")
remote_root = "/home/adminanmkavps/web/taallam.anmka.com/public_html/admin"

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(host, port=port, username=username, password=password, timeout=20)

try:
    sftp = client.open_sftp()
    try:
        sftp.stat(remote_root)
    except FileNotFoundError:
        sftp.mkdir(remote_root, mode=0o755)

    for name in ("index.html", "styles.css", "app.js", "api.php"):
        local_path = os.path.join(local_root, name)
        remote_path = posixpath.join(remote_root, name)
        sftp.put(local_path, remote_path)
        sftp.chmod(remote_path, 0o644)
        print(f"uploaded {name}")
    sftp.close()

    command = (
        f"chown -R adminanmkavps:adminanmkavps {remote_root} && "
        f"find {remote_root} -type d -exec chmod 755 {{}} \\; && "
        f"find {remote_root} -type f -exec chmod 644 {{}} \\; && "
        "nginx -t"
    )
    _, stdout, stderr = client.exec_command(command, timeout=30)
    print(stdout.read().decode("utf-8", "replace"))
    print(stderr.read().decode("utf-8", "replace"))
finally:
    client.close()
