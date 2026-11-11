import datetime
import os
import posixpath
import sys

import paramiko


HOST = "77.237.232.181"
PORT = 2222
USER = "root"
BASE = "/home/adminanmkavps/web/bouslty.anmka.com/public_html/arabic-educational-platform"


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        if new in text:
            print(f"{label}: already fixed", flush=True)
            return text
        raise RuntimeError(f"{label}: expected source was not found")
    print(f"{label}: patched", flush=True)
    return text.replace(old, new, 1)


password = os.environ.get("SSH_PASS")
if not password:
    raise SystemExit("SSH_PASS is required")

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(
    HOST,
    port=PORT,
    username=USER,
    password=password,
    timeout=30,
    allow_agent=False,
    look_for_keys=False,
)
sftp = client.open_sftp()
stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%SZ")


def read_remote(relative: str) -> str:
    with sftp.open(posixpath.join(BASE, relative), "r") as handle:
        return handle.read().decode("utf-8")


def write_remote(relative: str, original: str, updated: str) -> None:
    if original == updated:
        return
    remote = posixpath.join(BASE, relative)
    backup = f"{remote}.codex-backup-{stamp}"
    with sftp.open(backup, "w") as handle:
        handle.write(original)
    with sftp.open(remote, "w") as handle:
        handle.write(updated)
    print(f"backup: {backup}", flush=True)


layout_name = "app/layout.tsx"
layout = read_remote(layout_name)
updated_layout = layout.replace(
    'import { Analytics } from "@vercel/analytics/next"\n',
    "",
).replace("        <Analytics />\n", "")
if updated_layout == layout and ("@vercel/analytics" in layout or "<Analytics" in layout):
    raise RuntimeError("layout analytics syntax was not recognized")
print("layout analytics: removed" if updated_layout != layout else "layout analytics: already removed", flush=True)
write_remote(layout_name, layout, updated_layout)

api_name = "lib/api.ts"
api = read_remote(api_name)
updated_api = replace_once(
    api,
    "export function mediaUrl(path?: string | null): string {\n  if (!path) return ''\n",
    "export function mediaUrl(path?: string | null): string {\n  if (!path || path.includes('default_avatar')) return ''\n",
    "mediaUrl placeholder guard",
)
write_remote(api_name, api, updated_api)

avatar_name = "components/ui/avatar.tsx"
avatar = read_remote(avatar_name)
updated_avatar = replace_once(
    avatar,
    "function AvatarImage({\n  className,\n  ...props\n}: React.ComponentProps<typeof AvatarPrimitive.Image>) {",
    "function AvatarImage({\n  className,\n  src,\n  ...props\n}: React.ComponentProps<typeof AvatarPrimitive.Image>) {",
    "avatar src extraction",
)
updated_avatar = replace_once(
    updated_avatar,
    "      className={cn('aspect-square size-full', className)}\n      {...props}",
    "      className={cn('aspect-square size-full', className)}\n      src={typeof src === 'string' && src.includes('default_avatar') ? undefined : src}\n      {...props}",
    "avatar placeholder guard",
)
write_remote(avatar_name, avatar, updated_avatar)

sftp.close()


def run(command: str, timeout: int = 1200) -> None:
    print(f"RUN: {command}", flush=True)
    _, stdout, stderr = client.exec_command(command, timeout=timeout)
    out = stdout.read().decode("utf-8", "replace")
    err = stderr.read().decode("utf-8", "replace")
    code = stdout.channel.recv_exit_status()
    if out:
        print(out[-8000:], flush=True)
    if err.strip():
        print(err[-4000:], file=sys.stderr, flush=True)
    if code != 0:
        raise RuntimeError(f"remote command failed with exit code {code}")


run(f"cd {BASE} && npm run build:direct")
run("pm2 restart bouslty-anmka-student --update-env")
run(
    "sleep 4; "
    "curl -fsS -o /dev/null -w 'home=%{http_code}\\n' https://bouslty.anmka.com/; "
    f"if grep -Rqs --exclude='*.map' '/_vercel/insights/script.js' {BASE}/.next; "
    "then echo analytics_bundle=present; exit 3; else echo analytics_bundle=absent; fi; "
    f"if grep -Rqs --exclude='*.map' 'default_avatar.jpg' {BASE}/.next/static; "
    "then echo default_avatar_literal=present; else echo default_avatar_literal=absent; fi"
)
client.close()
print("FIX_COMPLETE", flush=True)
