CREATE DATABASE IF NOT EXISTS remindcare_db
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE remindcare_db;

CREATE TABLE IF NOT EXISTS medicines (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  name         VARCHAR(255) NOT NULL,
  generic_name VARCHAR(255),
  brand_name   VARCHAR(255),
  description  TEXT,
  created_at   DATETIME,
  updated_at   DATETIME
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO medicines (name, generic_name, brand_name, description, created_at, updated_at) VALUES
('Amlodipin 5mg',   'Amlodipine',          'Norvasc',    'Antihipertensi', NOW(), NOW()),
('Metformin 500mg', 'Metformin',            'Glucophage', 'Antidiabetes',   NOW(), NOW()),
('Simvastatin 10mg','Simvastatin',          'Zocor',      'Penurun kolesterol', NOW(), NOW()),
('Aspirin 80mg',    'Acetylsalicylic Acid', 'Ascardia',   'Antiplatelet',   NOW(), NOW()),
('Bisoprolol 5mg',  'Bisoprolol',           'Concor',     'Beta-blocker',   NOW(), NOW());
