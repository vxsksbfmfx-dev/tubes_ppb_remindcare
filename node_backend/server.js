/**
 * RemindCare — Node.js Backend
 * REST API (Express) + WebSocket (ws) menggantikan PHP native + Ratchet
 *
 * Struktur port:
 *   HTTP REST API : PORT (default 8000)
 *   WebSocket     : WS_PORT (default 8090)  — atau share port yang sama
 *
 * Jalankan: node server.js
 */

'use strict';

require('dotenv').config();

const express      = require('express');
const cors         = require('cors');
const mysql        = require('mysql2/promise');
const bcrypt       = require('bcryptjs');
const jwt          = require('jsonwebtoken');
const multer       = require('multer');
const path         = require('path');
const fs           = require('fs');
const https        = require('https');
const { WebSocketServer, WebSocket } = require('ws');
const http         = require('http');

// ─────────────────────────────────────────────
//  Konfigurasi
// ─────────────────────────────────────────────
const config = {
  port:        process.env.PORT        || 8000,
  wsPort:      process.env.WS_PORT     || 8090,
  jwtSecret:   process.env.JWT_SECRET  || 'remindcare_secret_key_ganti_di_production',
  jwtExpire:   process.env.JWT_EXPIRE  || '30d',
  internalWsToken: process.env.INTERNAL_WS_TOKEN || 'internal_ws_token_secret',
  db: {
    host:     process.env.DB_HOST     || '127.0.0.1',
    port:     parseInt(process.env.DB_PORT || '3306'),
    database: process.env.DB_NAME     || 'remindcare_db',
    user:     process.env.DB_USER     || 'root',
    password: process.env.DB_PASS     || '',
    charset:  'utf8mb4',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
  },
  googleClientId:    process.env.GOOGLE_CLIENT_ID    || '',
  fcmProjectId:      process.env.FCM_PROJECT_ID      || '',
  fcmServiceAccount: process.env.FCM_SERVICE_ACCOUNT || path.join(__dirname, 'storage/firebase-service-account.json'),
  storageAvatars:    path.join(__dirname, 'storage/avatars'),
};

// ─────────────────────────────────────────────
//  Database pool
// ─────────────────────────────────────────────
const pool = mysql.createPool(config.db);

async function db() {
  return pool;
}

async function query(sql, params = []) {
  const [rows] = await pool.execute(sql, params);
  return rows;
}

async function queryOne(sql, params = []) {
  const [rows] = await pool.execute(sql, params);
  return rows[0] || null;
}

// ─────────────────────────────────────────────
//  JWT helpers
// ─────────────────────────────────────────────
function generateToken(payload) {
  return jwt.sign(payload, config.jwtSecret, { expiresIn: config.jwtExpire });
}

function verifyToken(token) {
  try {
    return jwt.verify(token, config.jwtSecret);
  } catch {
    return null;
  }
}

// ─────────────────────────────────────────────
//  Middleware auth
// ─────────────────────────────────────────────
function authMiddleware(req, res, next) {
  const header = req.headers['authorization'] || '';
  const token  = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ success: false, message: 'Token diperlukan' });
  const payload = verifyToken(token);
  if (!payload) return res.status(401).json({ success: false, message: 'Token tidak valid atau sudah expired' });
  req.user = payload;
  next();
}

function resolveElderlyId(req) {
  if (req.user.role === 'elderly') return req.user.sub;
  const id = parseInt(req.query.elderly_id || '0');
  if (!id) throw { status: 400, message: 'elderly_id wajib diisi' };
  return id;
}

// ─────────────────────────────────────────────
//  Response helpers
// ─────────────────────────────────────────────
const ok  = (res, data, message = 'OK', status = 200) =>
  res.status(status).json({ success: true, message, data });

const err = (res, message, status = 400, errors = undefined) =>
  res.status(status).json({ success: false, message, ...(errors ? { errors } : {}) });

// ─────────────────────────────────────────────
//  Validasi sederhana
// ─────────────────────────────────────────────
function validate(data, rules) {
  const errors = {};
  for (const [field, rule] of Object.entries(rules)) {
    const parts = rule.split('|');
    for (const part of parts) {
      if (part === 'required' && !data[field]) {
        (errors[field] = errors[field] || []).push(`${field} wajib diisi`);
      }
      if (part.startsWith('min:')) {
        const min = parseInt(part.slice(4));
        if (data[field] && String(data[field]).length < min)
          (errors[field] = errors[field] || []).push(`${field} minimal ${min} karakter`);
      }
      if (part === 'email' && data[field] && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(data[field])) {
        (errors[field] = errors[field] || []).push(`${field} harus berupa email valid`);
      }
    }
  }
  return Object.keys(errors).length ? errors : null;
}

// ─────────────────────────────────────────────
//  Express App
// ─────────────────────────────────────────────
const app = express();

app.use(cors({ origin: '*', methods: ['GET','POST','PUT','DELETE','OPTIONS'] }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Static avatars
fs.mkdirSync(config.storageAvatars, { recursive: true });
app.use('/storage/avatars', express.static(config.storageAvatars));

// ─────────────────────────────────────────────
//  Multer — avatar upload
// ─────────────────────────────────────────────
const avatarStorage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, config.storageAvatars),
  filename:    (req, file, cb) => {
    const ext = path.extname(file.originalname) || '.jpg';
    cb(null, `user_${req.user.sub}_${Date.now()}${ext}`);
  },
});
const avatarUpload = multer({
  storage: avatarStorage,
  limits:  { fileSize: 2 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowed = ['image/jpeg','image/png','image/webp'];
    cb(allowed.includes(file.mimetype) ? null : new Error('Tipe file tidak didukung'), allowed.includes(file.mimetype));
  },
});

// ─────────────────────────────────────────────
//  WebSocket broadcast helper
// ─────────────────────────────────────────────
// rooms: Map<elderlyId, Map<resourceId, ws>>
const rooms = new Map();

function broadcastToElderlyRoom(elderlyId, payload, excludeWs = null) {
  const room = rooms.get(elderlyId);
  if (!room) return;
  const msg = JSON.stringify(payload);
  for (const ws of room.values()) {
    if (ws !== excludeWs && ws.readyState === WebSocket.OPEN) {
      ws.send(msg);
    }
  }
}

// ─────────────────────────────────────────────
//  ROUTES — Auth
// ─────────────────────────────────────────────
const authRouter = express.Router();

// POST /api/auth/register
authRouter.post('/register', async (req, res) => {
  try {
    const data = req.body;
    const errs = validate(data, { name: 'required', email: 'required|email', password: 'required|min:6' });
    if (errs) return err(res, 'Validasi gagal', 422, errs);

    const existing = await queryOne('SELECT id FROM users WHERE email = ?', [data.email]);
    if (existing) return err(res, 'Email sudah terdaftar', 409);

    const hash = await bcrypt.hash(data.password, 10);
    const now  = new Date();
    const [result] = await pool.execute(
      'INSERT INTO users (name,email,password,phone,role,created_at,updated_at) VALUES (?,?,?,?,?,?,?)',
      [data.name, data.email, hash, data.phone || null, data.role || 'family', now, now]
    );
    const id   = result.insertId;
    const user = await queryOne('SELECT id,name,email,phone,role,age,avatar,created_at FROM users WHERE id=?', [id]);
    const token = generateToken({ sub: id, role: user.role });
    ok(res, { user, token }, 'Registrasi berhasil', 201);
  } catch (e) {
    err(res, e.message || 'Server error', 500);
  }
});

// POST /api/auth/login
authRouter.post('/login', async (req, res) => {
  try {
    const data = req.body;
    const errs = validate(data, { email: 'required|email', password: 'required' });
    if (errs) return err(res, 'Validasi gagal', 422, errs);

    const user = await queryOne('SELECT * FROM users WHERE email=?', [data.email]);
    if (!user || !(await bcrypt.compare(data.password, user.password)))
      return err(res, 'Email atau password salah', 401);

    delete user.password;
    const token = generateToken({ sub: user.id, role: user.role });
    ok(res, { user, token }, 'Login berhasil');
  } catch (e) {
    err(res, e.message || 'Server error', 500);
  }
});

// GET /api/auth/me
authRouter.get('/me', authMiddleware, async (req, res) => {
  try {
    const user = await queryOne('SELECT id,name,email,phone,role,age,avatar,created_at FROM users WHERE id=?', [req.user.sub]);
    if (!user) return err(res, 'User tidak ditemukan', 404);
    ok(res, user);
  } catch (e) { err(res, e.message, 500); }
});

// POST /api/auth/refresh
authRouter.post('/refresh', authMiddleware, async (req, res) => {
  try {
    const user = await queryOne('SELECT id,role FROM users WHERE id=?', [req.user.sub]);
    if (!user) return err(res, 'User tidak ditemukan', 404);
    const token = generateToken({ sub: user.id, role: user.role });
    ok(res, { token }, 'Token diperbarui');
  } catch (e) { err(res, e.message, 500); }
});

// POST /api/auth/logout
authRouter.post('/logout', authMiddleware, (req, res) => {
  ok(res, null, 'Logout berhasil');
});

// POST /api/auth/google
authRouter.post('/google', async (req, res) => {
  try {
    const { id_token } = req.body;
    if (!id_token) return err(res, 'id_token wajib dikirim', 400);

    // Verifikasi ke Google
    const googleUser = await verifyGoogleToken(id_token);
    if (!googleUser) return err(res, 'Google token tidak valid', 401);

    const now = new Date();
    let user = await queryOne('SELECT * FROM users WHERE email=?', [googleUser.email]);
    if (!user) {
      const [r] = await pool.execute(
        'INSERT INTO users (name,email,google_id,avatar,email_verified,role,created_at,updated_at) VALUES (?,?,?,?,1,?,?,?)',
        [googleUser.name || 'User', googleUser.email, googleUser.sub, googleUser.picture || null, 'family', now, now]
      );
      user = await queryOne('SELECT * FROM users WHERE id=?', [r.insertId]);
    } else {
      await pool.execute('UPDATE users SET google_id=?,updated_at=? WHERE id=?', [googleUser.sub, now, user.id]);
      user = await queryOne('SELECT * FROM users WHERE id=?', [user.id]);
    }
    delete user.password;
    const token = generateToken({ sub: user.id, role: user.role });
    ok(res, { user, token }, 'Login Google berhasil');
  } catch (e) { err(res, e.message, 500); }
});

async function verifyGoogleToken(idToken) {
  return new Promise((resolve) => {
    const url = `https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(idToken)}`;
    https.get(url, (response) => {
      let data = '';
      response.on('data', chunk => data += chunk);
      response.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          if (parsed.error) return resolve(null);
          if (config.googleClientId && parsed.aud !== config.googleClientId) return resolve(null);
          resolve(parsed);
        } catch { resolve(null); }
      });
    }).on('error', () => resolve(null));
  });
}

// ─────────────────────────────────────────────
//  ROUTES — Users / Profile
// ─────────────────────────────────────────────
const userRouter = express.Router();
userRouter.use(authMiddleware);

// GET /api/users/me
userRouter.get('/me', async (req, res) => {
  try {
    const user = await queryOne('SELECT id,name,email,phone,role,age,avatar,created_at FROM users WHERE id=?', [req.user.sub]);
    if (!user) return err(res, 'User tidak ditemukan', 404);
    ok(res, user);
  } catch (e) { err(res, e.message, 500); }
});

// PUT /api/users/me
userRouter.put('/me', async (req, res) => {
  try {
    const data = req.body;
    const errs = validate(data, { name: 'required' });
    if (errs) return err(res, 'Validasi gagal', 422, errs);

    const now = new Date();
    await pool.execute(
      'UPDATE users SET name=?,phone=?,age=?,updated_at=? WHERE id=?',
      [data.name, data.phone || null, data.age ? parseInt(data.age) : null, now, req.user.sub]
    );
    const user = await queryOne('SELECT id,name,email,phone,role,age,avatar,created_at FROM users WHERE id=?', [req.user.sub]);
    ok(res, user, 'Profil berhasil diperbarui');
  } catch (e) { err(res, e.message, 500); }
});

// POST /api/users/me/avatar
userRouter.post('/me/avatar', avatarUpload.single('avatar'), async (req, res) => {
  try {
    if (!req.file) return err(res, 'File avatar wajib dikirim', 400);
    const avatarPath = '/storage/avatars/' + req.file.filename;

    // Hapus avatar lama
    const existing = await queryOne('SELECT avatar FROM users WHERE id=?', [req.user.sub]);
    if (existing?.avatar) {
      const oldPath = path.join(__dirname, existing.avatar);
      if (fs.existsSync(oldPath)) fs.unlinkSync(oldPath);
    }

    await pool.execute('UPDATE users SET avatar=?,updated_at=? WHERE id=?', [avatarPath, new Date(), req.user.sub]);
    const user = await queryOne('SELECT id,name,email,phone,role,age,avatar,created_at FROM users WHERE id=?', [req.user.sub]);
    ok(res, user, 'Avatar berhasil diperbarui');
  } catch (e) { err(res, e.message || 'Upload gagal', 400); }
});

// GET /api/users/:id
userRouter.get('/:id', async (req, res) => {
  try {
    const user = await queryOne('SELECT id,name,email,phone,role,age,avatar,created_at FROM users WHERE id=?', [req.params.id]);
    if (!user) return err(res, 'User tidak ditemukan', 404);
    ok(res, user);
  } catch (e) { err(res, e.message, 500); }
});

// ─────────────────────────────────────────────
//  ROUTES — Medicines
// ─────────────────────────────────────────────
const medicineRouter = express.Router();
medicineRouter.use(authMiddleware);

medicineRouter.get('/', async (req, res) => {
  try {
    const rows = await query('SELECT * FROM medicines WHERE deleted_at IS NULL ORDER BY name ASC');
    ok(res, rows);
  } catch (e) { err(res, e.message, 500); }
});

medicineRouter.get('/:id', async (req, res) => {
  try {
    const row = await queryOne('SELECT * FROM medicines WHERE id=? AND deleted_at IS NULL', [req.params.id]);
    if (!row) return err(res, 'Obat tidak ditemukan', 404);
    ok(res, row);
  } catch (e) { err(res, e.message, 500); }
});

medicineRouter.post('/', async (req, res) => {
  try {
    const { name, generic_name, brand_name, description } = req.body;
    if (!name) return err(res, 'Validasi gagal', 422, { name: ['name wajib diisi'] });
    const now = new Date();
    const [r] = await pool.execute(
      'INSERT INTO medicines (name,generic_name,brand_name,description,created_at,updated_at) VALUES (?,?,?,?,?,?)',
      [name, generic_name || null, brand_name || null, description || null, now, now]
    );
    const row = await queryOne('SELECT * FROM medicines WHERE id=?', [r.insertId]);
    ok(res, row, 'Obat ditambahkan', 201);
  } catch (e) { err(res, e.message, 500); }
});

medicineRouter.put('/:id', async (req, res) => {
  try {
    const { name, generic_name, brand_name, description } = req.body;
    await pool.execute(
      'UPDATE medicines SET name=?,generic_name=?,brand_name=?,description=?,updated_at=? WHERE id=?',
      [name, generic_name || null, brand_name || null, description || null, new Date(), req.params.id]
    );
    ok(res, null, 'Obat diperbarui');
  } catch (e) { err(res, e.message, 500); }
});

medicineRouter.delete('/:id', async (req, res) => {
  try {
    await pool.execute('UPDATE medicines SET deleted_at=? WHERE id=?', [new Date(), req.params.id]);
    ok(res, null, 'Obat dihapus');
  } catch (e) { err(res, e.message, 500); }
});

// ─────────────────────────────────────────────
//  ROUTES — Schedules
// ─────────────────────────────────────────────
const scheduleRouter = express.Router();
scheduleRouter.use(authMiddleware);

scheduleRouter.get('/', async (req, res) => {
  try {
    const elderlyId = resolveElderlyId(req);
    const rows = await query(
      'SELECT * FROM schedules WHERE elderly_user_id=? AND is_active=1 AND deleted_at IS NULL ORDER BY created_at DESC',
      [elderlyId]
    );
    const parsed = rows.map(r => ({
      ...r,
      times: JSON.parse(r.times || '[]'),
      days:  r.days ? JSON.parse(r.days) : null,
    }));
    ok(res, parsed);
  } catch (e) { err(res, e.message || 'Server error', e.status || 500); }
});

scheduleRouter.post('/', async (req, res) => {
  try {
    const data = req.body;
    const errs = validate(data, { medicine_id: 'required', dose: 'required', times: 'required', start_date: 'required' });
    if (errs) return err(res, 'Validasi gagal', 422, errs);

    const elderlyId = data.elderly_user_id || req.user.sub;
    const now = new Date();
    const [r] = await pool.execute(
      `INSERT INTO schedules
       (elderly_user_id,created_by,medicine_id,dose,dose_unit,times,days,start_date,end_date,notes,is_active,created_at,updated_at)
       VALUES (?,?,?,?,?,?,?,?,?,?,1,?,?)`,
      [elderlyId, req.user.sub, data.medicine_id, data.dose, data.dose_unit || 'tablet',
       JSON.stringify(data.times), data.days ? JSON.stringify(data.days) : null,
       data.start_date, data.end_date || null, data.notes || null, now, now]
    );
    ok(res, { id: r.insertId }, 'Jadwal ditambahkan', 201);
  } catch (e) { err(res, e.message, 500); }
});

scheduleRouter.put('/:id', async (req, res) => {
  try {
    const data  = req.body;
    const sets  = [];
    const params = [];
    const allowed = ['dose','dose_unit','times','days','start_date','end_date','notes','is_active'];
    for (const k of allowed) {
      if (k in data) {
        sets.push(`${k}=?`);
        params.push(['times','days'].includes(k) ? JSON.stringify(data[k]) : data[k]);
      }
    }
    if (sets.length) {
      params.push(new Date(), req.params.id);
      await pool.execute(`UPDATE schedules SET ${sets.join(',')},updated_at=? WHERE id=?`, params);
    }
    ok(res, null, 'Jadwal diperbarui');
  } catch (e) { err(res, e.message, 500); }
});

scheduleRouter.delete('/:id', async (req, res) => {
  try {
    await pool.execute('UPDATE schedules SET deleted_at=? WHERE id=?', [new Date(), req.params.id]);
    ok(res, null, 'Jadwal dihapus');
  } catch (e) { err(res, e.message, 500); }
});

// ─────────────────────────────────────────────
//  ROUTES — Reminder Logs
// ─────────────────────────────────────────────
const logRouter = express.Router();
logRouter.use(authMiddleware);

// GET /api/logs  — hari ini
logRouter.get('/', async (req, res) => {
  try {
    const elderlyId = resolveElderlyId(req);
    const today = new Date().toISOString().slice(0, 10);
    const rows = await query(
      `SELECT rl.*, m.name AS medicine_name, m.generic_name, s.dose, s.dose_unit, s.times
       FROM reminder_logs rl
       JOIN schedules s ON s.id = rl.schedule_id
       JOIN medicines m ON m.id = s.medicine_id
       WHERE rl.elderly_user_id=? AND DATE(rl.scheduled_at)=?
       ORDER BY rl.scheduled_at ASC`,
      [elderlyId, today]
    );
    ok(res, rows);
  } catch (e) { err(res, e.message || 'Server error', e.status || 500); }
});

// GET /api/logs/history
logRouter.get('/history', async (req, res) => {
  try {
    const elderlyId = resolveElderlyId(req);
    const date = req.query.date || '';
    const page = Math.max(1, parseInt(req.query.page || '1'));
    const per  = 20;
    const offset = (page - 1) * per;

    let where  = 'rl.elderly_user_id = ?';
    const params = [elderlyId];
    if (date) { where += ' AND DATE(rl.scheduled_at) = ?'; params.push(date); }

    const items = await query(
      `SELECT rl.*, m.name AS medicine_name, m.brand_name, s.dose, s.notes
       FROM reminder_logs rl
       LEFT JOIN schedules s ON s.id = rl.schedule_id
       LEFT JOIN medicines m ON m.id = s.medicine_id
       WHERE ${where}
       ORDER BY rl.scheduled_at DESC
       LIMIT ${per} OFFSET ${offset}`,
      params
    );

    const [{ total }] = await query(
      `SELECT COUNT(*) AS total FROM reminder_logs rl WHERE ${where}`, params
    );

    ok(res, { items, total, current_page: page, last_page: Math.ceil(total / per) });
  } catch (e) { err(res, e.message || 'Server error', e.status || 500); }
});

// GET /api/logs/stats
logRouter.get('/stats', async (req, res) => {
  try {
    const elderlyId = resolveElderlyId(req);
    const weekly = await query(
      `SELECT DATE(scheduled_at) AS tanggal, COUNT(*) AS total,
              SUM(status='confirmed') AS diminum, SUM(status='missed') AS terlewat
       FROM reminder_logs WHERE elderly_user_id=?
         AND scheduled_at >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
       GROUP BY DATE(scheduled_at) ORDER BY tanggal ASC`,
      [elderlyId]
    );
    const monthly = await queryOne(
      `SELECT COUNT(*) AS total,
              SUM(status='confirmed') AS diminum,
              SUM(status='missed') AS terlewat,
              SUM(status='pending') AS menunggu,
              ROUND(SUM(status='confirmed')*100.0/NULLIF(COUNT(*),0),1) AS persentase_kepatuhan
       FROM reminder_logs
       WHERE elderly_user_id=?
         AND MONTH(scheduled_at)=MONTH(CURDATE())
         AND YEAR(scheduled_at)=YEAR(CURDATE())`,
      [elderlyId]
    );
    ok(res, { weekly, monthly: monthly || {} });
  } catch (e) { err(res, e.message || 'Server error', e.status || 500); }
});

// POST /api/logs/:id/confirm
logRouter.post('/:id/confirm', async (req, res) => {
  try {
    const payload = req.user;
    const logRow  = await queryOne('SELECT * FROM reminder_logs WHERE id=?', [req.params.id]);
    if (!logRow) return err(res, 'Log tidak ditemukan', 404);
    if (logRow.status !== 'pending') return err(res, 'Log sudah dikonfirmasi atau terlewat', 400);

    await pool.execute(
      `UPDATE reminder_logs SET status='confirmed', taken_at=NOW(), confirmed_by=?, updated_at=NOW() WHERE id=?`,
      [`user:${payload.sub}`, req.params.id]
    );

    // Broadcast via WebSocket ke room elderly
    broadcastToElderlyRoom(logRow.elderly_user_id, {
      type:       'log_confirmed',
      elderly_id: logRow.elderly_user_id,
      data:       { log_id: logRow.id, status: 'confirmed', taken_at: new Date().toISOString() },
    });

    ok(res, null, 'Berhasil dikonfirmasi');
  } catch (e) { err(res, e.message, 500); }
});

// ─────────────────────────────────────────────
//  ROUTES — Dashboard
// ─────────────────────────────────────────────
const dashboardRouter = express.Router();
dashboardRouter.use(authMiddleware);

dashboardRouter.get('/', async (req, res) => {
  try {
    const elderlyId = resolveElderlyId(req);
    const today     = new Date().toISOString().slice(0, 10);
    const now       = new Date().toTimeString().slice(0, 8);

    const todayLogs = await query(
      `SELECT rl.*, m.name AS medicine_name, s.dose, s.dose_unit, s.times
       FROM reminder_logs rl
       JOIN schedules s ON s.id = rl.schedule_id
       JOIN medicines m ON m.id = s.medicine_id
       WHERE rl.elderly_user_id=? AND DATE(rl.scheduled_at)=?
       ORDER BY rl.scheduled_at ASC`,
      [elderlyId, today]
    );

    const total    = todayLogs.length;
    const diminum  = todayLogs.filter(l => l.status === 'confirmed').length;
    const terlewat = todayLogs.filter(l => l.status === 'missed').length;
    const menunggu = todayLogs.filter(l => l.status === 'pending').length;
    const persen   = total > 0 ? Math.round(diminum / total * 1000) / 10 : 0;

    const nextSchedule = todayLogs.find(l => l.status === 'pending' &&
      new Date(l.scheduled_at).toTimeString().slice(0,8) >= now) || null;

    const weekly = await query(
      `SELECT DATE(scheduled_at) AS tanggal, COUNT(*) AS total,
              SUM(status='confirmed') AS diminum, SUM(status='missed') AS terlewat
       FROM reminder_logs WHERE elderly_user_id=?
         AND scheduled_at >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
       GROUP BY DATE(scheduled_at) ORDER BY tanggal ASC`,
      [elderlyId]
    );

    const user = await queryOne('SELECT id,name,email,phone,role,age,avatar FROM users WHERE id=?', [req.user.sub]);

    ok(res, {
      today: { total, diminum, terlewat, menunggu, persen },
      next_schedule: nextSchedule,
      today_logs: todayLogs,
      weekly_stats: weekly,
      user,
    });
  } catch (e) { err(res, e.message || 'Server error', e.status || 500); }
});

// ─────────────────────────────────────────────
//  ROUTES — Notifications / FCM
// ─────────────────────────────────────────────
const notifRouter = express.Router();
notifRouter.use(authMiddleware);

// POST /api/fcm-token
notifRouter.post('/fcm-token', async (req, res) => {
  try {
    const { fcm_token } = req.body;
    if (!fcm_token) return err(res, 'fcm_token wajib diisi', 400);
    await pool.execute('UPDATE users SET fcm_token=?,updated_at=? WHERE id=?', [fcm_token, new Date(), req.user.sub]);
    ok(res, null, 'FCM token tersimpan');
  } catch (e) { err(res, e.message, 500); }
});

// POST /api/notifications/test
notifRouter.post('/test', async (req, res) => {
  try {
    const user = await queryOne('SELECT fcm_token FROM users WHERE id=?', [req.user.sub]);
    if (!user?.fcm_token) return err(res, 'FCM token belum tersimpan', 400);
    const sent = await fcmSendToToken(user.fcm_token, 'Test Notifikasi', 'RemindCare berjalan dengan baik!');
    ok(res, { sent }, sent ? 'Notifikasi terkirim' : 'Gagal mengirim notifikasi');
  } catch (e) { err(res, e.message, 500); }
});

// POST /api/notifications/remind
notifRouter.post('/remind', async (req, res) => {
  try {
    const { elderly_id, log_id } = req.body;
    const log  = await queryOne(
      `SELECT rl.*, m.name AS medicine_name, s.dose, s.dose_unit
       FROM reminder_logs rl
       JOIN schedules s ON s.id = rl.schedule_id
       JOIN medicines m ON m.id = s.medicine_id
       WHERE rl.id=?`,
      [log_id]
    );
    if (!log) return err(res, 'Log tidak ditemukan', 404);

    const user = await queryOne('SELECT fcm_token FROM users WHERE id=?', [log.elderly_user_id]);
    if (!user?.fcm_token) return err(res, 'FCM token tidak tersedia', 400);

    const sent = await fcmSendToToken(
      user.fcm_token,
      'Waktunya Minum Obat!',
      `${log.medicine_name} - ${log.dose} ${log.dose_unit}`,
      { log_id: String(log_id) }
    );
    ok(res, { sent });
  } catch (e) { err(res, e.message, 500); }
});

// ── FCM helper ──
async function fcmSendToToken(fcmToken, title, body, data = {}) {
  if (!config.fcmProjectId) return false;
  try {
    const accessToken = await getFcmAccessToken();
    if (!accessToken) return false;

    const payload = {
      message: {
        token: fcmToken,
        notification: { title, body },
        data: Object.fromEntries(Object.entries(data).map(([k,v]) => [k, String(v)])),
        android: { priority: 'high', notification: { channel_id: 'remindcare_reminder', sound: 'default' } },
        apns: { payload: { aps: { sound: 'default', badge: 1 } } },
      }
    };

    return new Promise((resolve) => {
      const postData = JSON.stringify(payload);
      const opts = {
        hostname: 'fcm.googleapis.com',
        path: `/v1/projects/${config.fcmProjectId}/messages:send`,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${accessToken}`,
          'Content-Length': Buffer.byteLength(postData),
        },
      };
      const req = https.request(opts, r => {
        let d = '';
        r.on('data', c => d += c);
        r.on('end', () => {
          try { const j = JSON.parse(d); resolve(!!j.name); } catch { resolve(false); }
        });
      });
      req.on('error', () => resolve(false));
      req.write(postData);
      req.end();
    });
  } catch { return false; }
}

async function getFcmAccessToken() {
  if (!fs.existsSync(config.fcmServiceAccount)) return null;
  try {
    const sa = JSON.parse(fs.readFileSync(config.fcmServiceAccount, 'utf8'));
    // JWT untuk Google OAuth2 (service account)
    const now  = Math.floor(Date.now() / 1000);
    const claim = {
      iss: sa.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      exp: now + 3600,
      iat: now,
    };
    const signedJwt = jwt.sign(claim, sa.private_key, { algorithm: 'RS256' });

    return new Promise((resolve) => {
      const postData = `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${signedJwt}`;
      const opts = {
        hostname: 'oauth2.googleapis.com',
        path: '/token',
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      };
      const req = https.request(opts, r => {
        let d = '';
        r.on('data', c => d += c);
        r.on('end', () => {
          try { const j = JSON.parse(d); resolve(j.access_token || null); } catch { resolve(null); }
        });
      });
      req.on('error', () => resolve(null));
      req.write(postData);
      req.end();
    });
  } catch { return null; }
}

// ─────────────────────────────────────────────
//  Register routes
// ─────────────────────────────────────────────
app.use('/api/auth',          authRouter);
app.use('/api/users',         userRouter);
app.use('/api/medicines',     medicineRouter);
app.use('/api/schedules',     scheduleRouter);
app.use('/api/logs',          logRouter);
app.use('/api/dashboard',     dashboardRouter);
app.use('/api/notifications', notifRouter);
app.post('/api/fcm-token', authMiddleware, notifRouter);

// Health check
app.get('/', (req, res) => res.json({ app: 'RemindCare API (Node.js)', version: '1.0.0', status: 'OK' }));

// ─────────────────────────────────────────────
//  HTTP Server
// ─────────────────────────────────────────────
const server = http.createServer(app);

server.listen(config.port, () => {
  console.log(`╔══════════════════════════════════════════════╗`);
  console.log(`║  RemindCare REST API (Node.js + Express)     ║`);
  console.log(`║  http://0.0.0.0:${config.port}                       ║`);
  console.log(`╚══════════════════════════════════════════════╝`);
});

// ─────────────────────────────────────────────
//  WebSocket Server (port terpisah: WS_PORT)
//  Protocol JSON sama seperti PHP Ratchet:
//    { type:"auth",      token:"..." }
//    { type:"subscribe", elderly_id: 5 }
//    { type:"broadcast", elderly_id: 5, event:"update", data:{} }
// ─────────────────────────────────────────────
const wss = new WebSocketServer({ port: parseInt(config.wsPort) });
let wsIdCounter = 0;

wss.on('connection', (ws) => {
  ws._id   = ++wsIdCounter;
  ws._user = null;
  ws._rooms = [];

  console.log(`[WS] New connection #${ws._id}`);

  ws.on('message', (raw) => {
    let data;
    try { data = JSON.parse(raw.toString()); } catch {
      ws.send(JSON.stringify({ type: 'error', message: 'Format pesan tidak valid' }));
      return;
    }

    switch (data.type) {
      case 'auth':      handleWsAuth(ws, data);      break;
      case 'subscribe': handleWsSubscribe(ws, data); break;
      case 'broadcast': handleWsBroadcast(ws, data); break;
      default:
        ws.send(JSON.stringify({ type: 'error', message: 'Tipe tidak dikenal' }));
    }
  });

  ws.on('close', () => {
    for (const elderlyId of ws._rooms) {
      const room = rooms.get(elderlyId);
      if (room) { room.delete(ws._id); if (!room.size) rooms.delete(elderlyId); }
    }
    console.log(`[WS] Connection #${ws._id} closed`);
  });

  ws.on('error', (e) => {
    console.error(`[WS] Error #${ws._id}:`, e.message);
    ws.close();
  });
});

function handleWsAuth(ws, data) {
  const payload = verifyToken(data.token || '');
  if (!payload) {
    ws.send(JSON.stringify({ type: 'error', message: 'Token tidak valid' }));
    ws.close();
    return;
  }
  ws._user = payload;
  ws.send(JSON.stringify({ type: 'auth_ok', user_id: payload.sub }));
  console.log(`[WS] Authenticated #${ws._id} as user ${payload.sub}`);
}

function handleWsSubscribe(ws, data) {
  if (!ws._user) {
    ws.send(JSON.stringify({ type: 'error', message: 'Belum autentikasi' }));
    return;
  }
  const elderlyId = parseInt(data.elderly_id || ws._user.sub);
  if (!rooms.has(elderlyId)) rooms.set(elderlyId, new Map());
  rooms.get(elderlyId).set(ws._id, ws);
  ws._rooms.push(elderlyId);
  ws.send(JSON.stringify({ type: 'subscribed', elderly_id: elderlyId }));
  console.log(`[WS] #${ws._id} subscribed to elderly:${elderlyId}`);
}

function handleWsBroadcast(ws, data) {
  if (!ws._user) return;
  const elderlyId = parseInt(data.elderly_id || 0);
  if (!elderlyId) return;
  broadcastToElderlyRoom(elderlyId, {
    type:       data.event || 'update',
    elderly_id: elderlyId,
    data:       data.data || null,
  }, ws);
  console.log(`[WS] Broadcast to elderly:${elderlyId}`);
}

console.log(`╔══════════════════════════════════════════════╗`);
console.log(`║  RemindCare WebSocket Server (Node.js ws)    ║`);
console.log(`║  ws://0.0.0.0:${config.wsPort}                       ║`);
console.log(`╚══════════════════════════════════════════════╝`);

module.exports = { app, server, wss };
