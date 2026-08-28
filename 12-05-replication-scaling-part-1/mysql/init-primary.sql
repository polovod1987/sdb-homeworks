CREATE USER IF NOT EXISTS 'repl'@'%' IDENTIFIED BY 'replica_password';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
FLUSH PRIVILEGES;

USE replication_demo;
CREATE TABLE IF NOT EXISTS replication_check (
  id INT PRIMARY KEY AUTO_INCREMENT,
  message VARCHAR(255) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO replication_check (message)
VALUES ('created on primary before replica start');
