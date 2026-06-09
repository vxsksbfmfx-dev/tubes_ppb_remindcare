USE remindcare_db;

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS google_id       VARCHAR(100) DEFAULT NULL AFTER role,
  ADD COLUMN IF NOT EXISTS email_verified  TINYINT(1)   DEFAULT 0   AFTER google_id,
  ADD UNIQUE INDEX IF NOT EXISTS uq_google_id (google_id);
