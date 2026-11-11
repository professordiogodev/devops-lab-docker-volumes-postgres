#!/usr/bin/env python3
import glob, json, os, subprocess, sys, time
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
os.chdir(ROOT)
passed = failed = 0


def check(desc, ok, hint=""):
    global passed, failed
    if ok:
        passed += 1; print("PASS  " + desc, flush=True)
    else:
        failed += 1; print("FAIL  " + desc + (("   -> " + hint) if hint else ""), flush=True)


def finish():
    print()
    print(("ALL CHECKS PASSED (%d/%d)" % (passed, passed)) if failed == 0 else ("%d check(s) failed, %d passed" % (failed, passed)))
    sys.exit(1 if failed else 0)


def sh(*a, timeout=240):
    r = subprocess.run(a, capture_output=True, text=True, timeout=timeout)
    return r.returncode, r.stdout, r.stderr


def count():
    rc, out, err = sh("docker", "compose", "exec", "-T", "db", "psql", "-U", "pollie", "-d", "pollie", "-tA", "-c", "SELECT count(*) FROM polls")
    return int(out.strip()) if rc == 0 and out.strip().isdigit() else -1


def up():
    rc, out, err = sh("docker", "compose", "up", "-d", "--wait", "--wait-timeout", "90")
    time.sleep(2)
    return rc == 0


truth = json.load(open(".lab/.truth.json"))["id"]
print("== What you rescued ==")
rec = open("backups/recovered.sql").read() if os.path.exists("backups/recovered.sql") else ""
check("backups/recovered.sql contains the three polls of the old database", all(t in rec for t in ("Tabs or spaces? " + truth, "Best standup time? " + truth, "Friday deploys? " + truth)), "recover them from the orphaned volume (docker volume ls)")
print("== compose.yaml ==")
rc, out, err = sh("docker", "compose", "config", "--format", "json")
check("compose.yaml is valid", rc == 0, err[-200:])
if rc != 0:
    finish()
cfg = json.loads(out)
svc = cfg["services"].get("db", {})
check("the service is called db and uses postgres:16", svc.get("image", "").startswith("postgres:16"))
vols = svc.get("volumes", [])
check("the data lives in a NAMED volume mounted at /var/lib/postgresql/data", any(v.get("type") == "volume" and v.get("target") == "/var/lib/postgresql/data" and v.get("source") for v in vols))
env = svc.get("environment", {}) or {}
check("the password is NOT an environment value; the container reads POSTGRES_PASSWORD_FILE", "POSTGRES_PASSWORD" not in env and env.get("POSTGRES_PASSWORD_FILE", "").startswith("/run/secrets/"))
check("a Compose secret feeds it, from a file of 16+ characters that git ignores", bool(svc.get("secrets")) and os.path.exists("secrets/db_password.txt") and len(open("secrets/db_password.txt").read().strip()) >= 16)
check("no published ports (the database is not on the host's network)", not svc.get("ports"))
check("a healthcheck and a restart policy", bool(svc.get("healthcheck")) and svc.get("restart") in ("unless-stopped", "always", "on-failure"))
check("backup.sh uses pg_dump with --clean and restore.sh uses psql", "pg_dump" in open("backup.sh").read() and "--clean" in open("backup.sh").read() and "psql" in open("restore.sh").read())

print("== Redeploy, back up, destroy, restore ==")
sh("docker", "compose", "down", "-v")
check("the database starts and becomes healthy (docker compose up --wait)", up(), "docker compose logs db")
rc, out, err = sh("./restore.sh", "backups/recovered.sql")
check("restore.sh loads the rescued polls into the new database", rc == 0 and count() == 3, (out + err)[-200:])
for f in glob.glob("backups/pollie-*.sql"):
    os.remove(f)
rc, out, err = sh("./backup.sh")
dumps = sorted(glob.glob("backups/pollie-*.sql"))
check("backup.sh writes backups/pollie-<time>.sql that is not empty", rc == 0 and bool(dumps) and os.path.getsize(dumps[-1]) > 200, (out + err)[-200:])
sh("docker", "compose", "down")
check("after a redeploy (down, then up) the three polls are still there", up() and count() == 3, "is the volume named? is there a volume line?")
sh("docker", "compose", "down", "-v")
check("after `down -v` (volume destroyed) the new database is empty", up() and count() in (0, -1))
rc, out, err = sh("./restore.sh", dumps[-1] if dumps else "backups/none.sql")
check("restoring the backup into the EMPTY database brings the three polls back", rc == 0 and count() == 3, (out + err)[-200:])
rc, out, err = sh("./restore.sh", "backups/does-not-exist.sql")
check("restore.sh refuses a file that does not exist (non-zero exit)", rc != 0)
sh("docker", "compose", "down", "-v")
finish()
