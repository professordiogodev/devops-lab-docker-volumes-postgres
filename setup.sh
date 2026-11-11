#!/usr/bin/env bash
# Starts the legacy database, adds three polls, then "deploys" (down + up). Run: ./setup.sh
set -u
cd "$(dirname "$0")"
for c in docker python3; do command -v "$c" >/dev/null || { echo "MISSING: $c"; exit 1; }; done
docker info >/dev/null 2>&1 || { echo "Docker is not running."; exit 1; }
docker compose version >/dev/null 2>&1 || { echo "Docker Compose v2 is missing."; exit 1; }
if (exec 3<>/dev/tcp/127.0.0.1/5432) 2>/dev/null; then echo "Port 5432 is in use on your machine. Stop whatever uses it first."; exit 1; fi
ID=$(python3 -c 'import secrets;print(secrets.token_hex(3))')
docker compose -f compose.legacy.yaml up -d >/dev/null 2>&1 || { echo "could not start the legacy database"; exit 1; }
for _ in $(seq 1 40); do docker compose -f compose.legacy.yaml exec -T db pg_isready -U pollie >/dev/null 2>&1 && break; sleep 1; done
sleep 3
docker compose -f compose.legacy.yaml exec -T db psql -U pollie -d pollie -q -c "CREATE TABLE polls (id serial PRIMARY KEY, title text NOT NULL, created_at timestamptz DEFAULT now()); INSERT INTO polls (title) VALUES ('Tabs or spaces? $ID'), ('Best standup time? $ID'), ('Friday deploys? $ID');" >/dev/null
CID=$(docker compose -f compose.legacy.yaml ps -q db)
docker inspect "$CID" --format '{{range .Mounts}}{{.Name}}{{"\n"}}{{end}}' | grep -v '^$' > .lab/.volumes
printf '{"id": "%s"}\n' "$ID" > .lab/.truth.json
echo "Three polls are in the database. Now the weekly deploy:"
docker compose -f compose.legacy.yaml down >/dev/null 2>&1
docker compose -f compose.legacy.yaml up -d >/dev/null 2>&1
for _ in $(seq 1 40); do docker compose -f compose.legacy.yaml exec -T db pg_isready -U pollie >/dev/null 2>&1 && break; sleep 1; done
sleep 3
echo "polls in the database after the deploy:"
docker compose -f compose.legacy.yaml exec -T db psql -U pollie -d pollie -tA -c "SELECT count(*) FROM polls" 2>&1 | head -1
echo "Your move. Start with:  docker volume ls"
