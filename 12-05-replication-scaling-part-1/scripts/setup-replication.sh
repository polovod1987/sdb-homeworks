#!/usr/bin/env bash
set -euo pipefail

docker compose up -d

until docker compose exec -T mysql-primary \
  mysqladmin ping -h 127.0.0.1 -uroot -proot_password --silent; do
  sleep 2
done

until docker compose exec -T mysql-replica \
  mysqladmin ping -h 127.0.0.1 -uroot -proot_password --silent; do
  sleep 2
done

docker compose exec -T mysql-replica mysql -uroot -proot_password <<'SQL'
STOP REPLICA;
RESET REPLICA ALL;
CHANGE REPLICATION SOURCE TO
  SOURCE_HOST='mysql-primary',
  SOURCE_PORT=3306,
  SOURCE_USER='repl',
  SOURCE_PASSWORD='replica_password',
  SOURCE_AUTO_POSITION=1,
  GET_SOURCE_PUBLIC_KEY=1;
START REPLICA;
SET GLOBAL read_only=ON;
SET GLOBAL super_read_only=ON;
SQL

sleep 3
docker compose exec -T mysql-replica mysql -uroot -proot_password \
  -e "SHOW REPLICA STATUS\G"
