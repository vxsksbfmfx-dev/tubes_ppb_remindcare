#!/bin/bash
# Patch generate6.sh agar tidak append duplikat ke config.php
# Jalankan ini SEBELUM generate6.sh, atau ganti bagian cat >> di generate6.sh

# Ganti semua "cat >> backend/src/Config/config.php" 
# dengan pengecekan — hanya tambah jika belum ada

CONFIG="backend/src/Config/config.php"

add_if_missing() {
  local marker="$1"
  local content="$2"
  if ! grep -q "$marker" "$CONFIG"; then
    echo "$content" >> "$CONFIG"
    echo "  ✔ Ditambahkan: $marker"
  else
    echo "  ⚠ Skip (sudah ada): $marker"
  fi
}

add_if_missing "GOOGLE_CLIENT_ID" "
// ── Google OAuth ───────────────────────────────────────────
define('GOOGLE_CLIENT_ID', 'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com');"

add_if_missing "INTERNAL_BROADCAST_TOKEN" "
define('INTERNAL_BROADCAST_TOKEN', 'internal_ws_token_secret');"

add_if_missing "FCM_PROJECT_ID" "
// ── Firebase / FCM ─────────────────────────────────────────
define('FCM_PROJECT_ID',      'your-firebase-project-id');
define('FCM_SERVICE_ACCOUNT', BASE_PATH . '/storage/firebase-service-account.json');"
