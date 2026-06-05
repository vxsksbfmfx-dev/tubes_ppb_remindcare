CREATE TABLE IF NOT EXISTS medicines (
    id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name         VARCHAR(150) NOT NULL,
    generic_name VARCHAR(150) DEFAULT NULL,
    brand_name   VARCHAR(150) DEFAULT NULL,
    description  TEXT         DEFAULT NULL,
    image        VARCHAR(255) DEFAULT NULL,
    created_at   DATETIME     NOT NULL,
    updated_at   DATETIME     NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
