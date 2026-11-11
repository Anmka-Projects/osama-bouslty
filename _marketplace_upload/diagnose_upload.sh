set -eu
BASE=/home/adminanmkavps/web/bouslty.anmka.com/public_html/backend
echo '===== UPLOAD REFERENCES ====='
grep -RIn --include='*.js' -E "router\.(post|put).*upload|multer|type.*image|fileFilter|mimetype" \
  "$BASE/src" | head -200 || true
echo '===== UPLOAD FILES ====='
find "$BASE/src" -type f -iname '*upload*' -maxdepth 6 -print
echo '===== UPLOAD MIDDLEWARE ====='
sed -n '1,210p' "$BASE/src/shared/middleware/upload.middleware.js"
echo '===== UPLOAD ROUTE ====='
sed -n '40,100p' "$BASE/src/routes.js"
