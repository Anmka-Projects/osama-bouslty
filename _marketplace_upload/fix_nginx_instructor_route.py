import os
import posixpath
import time

import paramiko


HOST = "77.237.232.181"
PORT = 2222
USER = "root"
FILES = [
    "/home/adminanmkavps/conf/web/bouslty.anmka.com/nginx.ssl.conf_routing",
    "/home/adminanmkavps/conf/web/bouslty.anmka.com/nginx.conf_routing",
]
OLD = "login|register|forgot-password|dashboard|instructor|courses|categories|instructors|checkout"
NEW = "login|register|forgot-password|dashboard|instructor|chat|courses|categories|instructors|checkout"


client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(
    HOST,
    port=PORT,
    username=USER,
    password=os.environ["SSH_PASS"],
    timeout=40,
    allow_agent=False,
    look_for_keys=False,
)
sftp = client.open_sftp()
stamp = time.strftime("%Y%m%d-%H%M%S")
backups = []
backup_dir = f"/home/adminanmkavps/web/bouslty.anmka.com/public_html/deploy-backups/nginx-instructor-{stamp}"

try:
    # Hestia includes nginx.conf_* as configuration. Backups beside the source
    # would therefore be parsed as extra configs and create duplicate locations.
    stale_dir = f"/home/adminanmkavps/web/bouslty.anmka.com/public_html/deploy-backups/nginx-stale-{stamp}"
    cleanup = (
        f"mkdir -p '{backup_dir}' '{stale_dir}'; "
        "for f in "
        "/home/adminanmkavps/conf/web/bouslty.anmka.com/nginx.ssl.conf_routing.bak-* "
        "/home/adminanmkavps/conf/web/bouslty.anmka.com/nginx.conf_routing.bak-* "
        "/home/adminanmkavps/conf/web/bouslty.anmka.com/nginx.ssl.conf_routing.codex-upload "
        "/home/adminanmkavps/conf/web/bouslty.anmka.com/nginx.conf_routing.codex-upload; "
        f"do test ! -e \"$f\" || mv \"$f\" '{stale_dir}/'; done"
    )
    _, stdout, stderr = client.exec_command(cleanup, timeout=60)
    if stdout.channel.recv_exit_status() != 0:
        raise RuntimeError(stderr.read().decode("utf-8", "replace"))

    for remote in FILES:
        backup = posixpath.join(backup_dir, posixpath.basename(remote))
        _, stdout, stderr = client.exec_command(f"cp '{remote}' '{backup}'", timeout=30)
        if stdout.channel.recv_exit_status() != 0:
            raise RuntimeError(stderr.read().decode("utf-8", "replace"))
        backups.append((remote, backup))
        with sftp.open(remote, "r") as handle:
            text = handle.read().decode("utf-8")
        if NEW in text:
            continue
        if OLD not in text:
            raise RuntimeError(f"Routing pattern not found in {remote}")
        updated = text.replace(OLD, NEW, 1)
        temporary = posixpath.join(posixpath.dirname(remote), f".codex-{posixpath.basename(remote)}-{stamp}")
        with sftp.open(temporary, "w") as handle:
            handle.write(updated)
        sftp.posix_rename(temporary, remote)

    _, stdout, stderr = client.exec_command("nginx -t", timeout=60)
    validation = stdout.read().decode("utf-8", "replace") + stderr.read().decode("utf-8", "replace")
    if stdout.channel.recv_exit_status() != 0:
        for remote, backup in backups:
            client.exec_command(f"cp '{backup}' '{remote}'", timeout=30)
        raise RuntimeError(validation)
    print(validation)

    _, stdout, stderr = client.exec_command("systemctl reload nginx", timeout=60)
    reload_output = stdout.read().decode("utf-8", "replace") + stderr.read().decode("utf-8", "replace")
    if stdout.channel.recv_exit_status() != 0:
        raise RuntimeError(reload_output)
    print("NGINX_RELOADED")
finally:
    sftp.close()
    client.close()
