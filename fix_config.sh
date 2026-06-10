#!/bin/bash
# Fix config.php — hapus duplikat define, fix syntax \n literal
set -e
GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'

CONFIG="backend/src/Config/config.php"

cat > "$CONFIG" << 'PHPEOF'
<?php
// ── Env ────────────────────────────────────────────────────
define('APP_NAME',    'RemindCare API');
define('APP_VERSION', '1.0.0');
define('APP_ENV',     'development');

// ── Database ───────────────────────────────────────────────
define('DB_HOST',    '127.0.0.1');
define('DB_PORT',    '3306');
define('DB_NAME',    'remindcare_db');
define('DB_USER',    'root');
define('DB_PASS',    '');
define('DB_CHARSET', 'utf8mb4');

// ── CORS ───────────────────────────────────────────────────
define('ALLOWED_ORIGINS', ['*']);

// ── JWT ────────────────────────────────────────────────────
define('JWT_SECRET', 'remindcare_secret_key_ganti_di_production');
define('JWT_EXPIRE', 86400 * 30);

// ── Internal Token ─────────────────────────────────────────
define('INTERNAL_BROADCAST_TOKEN', 'internal_ws_token_secret');

// ── Google OAuth ───────────────────────────────────────────
// Ganti dengan Web Client ID dari Google Cloud Console
define('GOOGLE_CLIENT_ID', 'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com');

// ── Firebase / FCM ─────────────────────────────────────────
define('FCM_PROJECT_ID',      'your-firebase-project-id');
define('FCM_SERVICE_ACCOUNT', BASE_PATH . '/storage/firebase-service-account.json');
PHPEOF

echo -e "${GREEN}✔ config.php bersih${NC}"

# Cek syntax PHP
php -l "$CONFIG" && echo -e "${GREEN}✔ Syntax PHP OK${NC}" || echo "❌ Ada error syntax"
