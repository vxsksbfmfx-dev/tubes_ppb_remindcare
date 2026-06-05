<?php
// ── Env sederhana ──────────────────────────────────────────
define('APP_NAME',    'RemindCare API');
define('APP_VERSION', '1.0.0');
define('APP_ENV',     'development');

// ── Database ───────────────────────────────────────────────
define('DB_HOST',     '127.0.0.1');
define('DB_PORT',     '3306');
define('DB_NAME',     'remindcare_db');
define('DB_USER',     'root');
define('DB_PASS',     '');
define('DB_CHARSET',  'utf8mb4');

// ── CORS ───────────────────────────────────────────────────
define('ALLOWED_ORIGINS', ['*']);

// ── JWT ────────────────────────────────────────────────────
define('JWT_SECRET',  'remindcare_secret_key_ganti_di_production');
define('JWT_EXPIRE',  86400 * 30); // 30 hari
