#!/usr/bin/env bash
# Proves the lab left nothing on your machine. Run with: ./verify-teardown.sh
set -u
cd "$(dirname "$0")"
pass=0; failn=0
check() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then echo "PASS  $d"; pass=$((pass+1)); else echo "FAIL  $d"; failn=$((failn+1)); fi; }
check "no container of the projects pollie-legacy or pollie-db" bash -c '[ -z "$(docker ps -aq --filter label=com.docker.compose.project=pollie-legacy --filter label=com.docker.compose.project=pollie-db)" ]'
check "no volume of the projects pollie-legacy or pollie-db" bash -c '[ -z "$(docker volume ls -q --filter label=com.docker.compose.project=pollie-legacy --filter label=com.docker.compose.project=pollie-db)" ]'
check "the old anonymous volume is gone" bash -c '[ ! -f .lab/.volumes ] || ! while read -r v; do docker volume inspect "$v" >/dev/null 2>&1 && exit 1; done < .lab/.volumes'
check "the generated secret and backups are gone" bash -c '[ ! -f secrets/db_password.txt ] && [ -z "$(ls backups/pollie-*.sql 2>/dev/null)" ]'
echo
if [ "$failn" -eq 0 ]; then echo "TEARDOWN VERIFIED ($pass/$pass) on this machine"; else echo "NOT CLEAN: $failn leftover(s). Remove them and run this again."; fi
exit "$failn"
