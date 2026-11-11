#!/usr/bin/env bash
rc=0
grep -q 'pgdata' compose.yaml && grep -q 'POSTGRES_PASSWORD_FILE' compose.yaml && echo "- ✅ compose.yaml has a named volume and a password file" || { echo "- ❌ compose.yaml needs a named volume (pgdata) and POSTGRES_PASSWORD_FILE"; rc=1; }
grep -q 'pg_dump' backup.sh && grep -q 'psql' restore.sh && echo "- ✅ backup.sh and restore.sh are written" || { echo "- ❌ backup.sh / restore.sh are not written"; rc=1; }
test -s backups/recovered.sql && echo "- ✅ backups/recovered.sql is there" || { echo "- ❌ backups/recovered.sql is missing"; rc=1; }
git ls-files | grep -q 'secrets/db_password' && { echo "- ❌ the password file is committed"; rc=1; } || echo "- ✅ no password file committed"
grep -qE '^ALL CHECKS PASSED \(' SUBMISSION.md && echo "- ✅ SUBMISSION.md shows ALL CHECKS PASSED" || { echo "- ❌ paste the verify.sh output ('ALL CHECKS PASSED') into SUBMISSION.md"; rc=1; }
exit $rc
