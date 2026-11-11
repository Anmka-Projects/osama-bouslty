set -eu
BASE=/home/adminanmkavps/web/bouslty.anmka.com/public_html/arabic-educational-platform
echo '===== LAYOUT ====='
sed -n '1,220p' "$BASE/app/layout.tsx"
echo '===== MATCHES ====='
grep -RIn \
  --include='*.ts' \
  --include='*.tsx' \
  --include='*.js' \
  -E 'default_avatar|@vercel/analytics|<Analytics' \
  "$BASE/app" "$BASE/components" "$BASE/lib" | head -160 || true
echo '===== MEDIA URL ====='
grep -n -A 45 -B 10 -E 'function mediaUrl|const mediaUrl|export.*mediaUrl' "$BASE/lib/api.ts" || true
echo '===== AVATAR USAGE ====='
grep -RIn --include='*.tsx' -E 'mediaUrl\(.*avatar|AvatarImage|default_avatar' \
  "$BASE/app/instructors" "$BASE/components" | head -120 || true
echo '===== AVATAR COMPONENT ====='
sed -n '1,100p' "$BASE/components/ui/avatar.tsx"
echo '===== NAVBAR IMPORTS ====='
sed -n '1,35p' "$BASE/components/navbar.tsx"
echo '===== PM2 ====='
pm2 jlist | node -e "let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{for(const p of JSON.parse(s)) if((p.name||'').includes('bouslty')) console.log(p.name,p.pm2_env.status,p.pm2_env.pm_cwd)})"
