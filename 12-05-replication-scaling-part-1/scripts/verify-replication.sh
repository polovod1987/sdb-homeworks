#!/usr/bin/env bash
set -euo pipefail

stamp="replication check $(date -u +%Y-%m-%dT%H:%M:%SZ)"

docker compose exec -T mysql-primary mysql -uroot -proot_password \
  replication_demo -e \
  "INSERT INTO replication_check (message) VALUES ('$stamp');"

replicated=0
for _ in {1..20}; do
  if docker compose exec -T mysql-replica mysql -uroot -proot_password \
    replication_demo -Nse \
    "SELECT COUNT(*) FROM replication_check WHERE message='$stamp'" \
    | grep -qx '1'; then
    replicated=1
    break
  fi
  sleep 1
done

if [[ "$replicated" -ne 1 ]]; then
  echo "Replication test failed: row did not appear on replica" >&2
  exit 1
fi

echo "PRIMARY DATA"
docker compose exec -T mysql-primary mysql -uroot -proot_password \
  replication_demo \
  -e "SELECT id, message, created_at FROM replication_check ORDER BY id;"

echo "REPLICA DATA"
docker compose exec -T mysql-replica mysql -uroot -proot_password \
  replication_demo \
  -e "SELECT id, message, created_at FROM replication_check ORDER BY id;"

echo "SERVER MODES"
docker compose exec -T mysql-primary mysql -uroot -proot_password -Nse \
  "SELECT 'primary', @@server_id, @@read_only, @@super_read_only, @@gtid_mode;"
docker compose exec -T mysql-replica mysql -uroot -proot_password -Nse \
  "SELECT 'replica', @@server_id, @@read_only, @@super_read_only, @@gtid_mode;"

echo "REPLICA THREADS"
docker compose exec -T mysql-replica mysql -uroot -proot_password \
  -e "SHOW REPLICA STATUS\G" | grep -E \
  'Replica_IO_Running:|Replica_SQL_Running:|Seconds_Behind_Source:|Source_Host:|Source_Server_Id:|Auto_Position:'
