USE remindcare_db;

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS fcm_token VARCHAR(255) DEFAULT NULL AFTER email_verified;
