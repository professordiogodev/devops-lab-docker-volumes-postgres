#!/usr/bin/env bash
# Removes the lab's containers, volumes (including the old orphaned one) and generated files. Run with: ./teardown.sh
set -u
cd "$(dirname "$0")"
docker compose -f compose.legacy.yaml down -v >/dev/null 2>&1
docker compose -p pollie-db -f compose.yaml down -v >/dev/null 2>&1
docker ps -aq --filter label=com.docker.compose.project=pollie-legacy | xargs -r docker rm -f >/dev/null 2>&1
if [ -f .lab/.volumes ]; then while read -r v; do [ -n "$v" ] && docker volume rm -f "$v" >/dev/null 2>&1 && echo "removed the old volume ${v:0:12}..."; done < .lab/.volumes; fi
docker ps -aq --filter name=voltmp | xargs -r docker rm -f >/dev/null 2>&1
rm -f .lab/.truth.json .lab/.volumes secrets/db_password.txt backups/pollie-*.sql
echo "Now run ./verify-teardown.sh"
