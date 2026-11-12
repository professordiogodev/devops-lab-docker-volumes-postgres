# LAB | Docker: The Database That Forgot Every Deploy

## The situation

```text
RESCUE LOG - Pollie test database
Day 1  : the weekly deploy ran. The polls created this week are gone.
Day 1  : previous engineer: "containers are ephemeral, that's how Docker works."
Day 1  : half true. The false half is expensive.
Search : the data is probably NOT gone. It is on the disk, in a volume that
         nobody named and nobody looks at.
```

Two missions, in this order. **Mission 1: find the data and rescue it.** **Mission 2: build the database container the right way**, with the data in a named volume, the password in a secret and not in the compose file, no port open to the world, and a backup script that someone has actually restored from.

> **Your mission**
> - Run the weekly deploy and watch the polls disappear
> - Find the orphaned volume, recover the three polls into `backups/recovered.sql`
> - Write `compose.yaml` for a database that keeps its data and its secret
> - Write `backup.sh` and `restore.sh`, then destroy the database and bring it back from a backup
> - Tear down and prove it

**Time:** 90-105 min | **Cost:** free | **You need:** Docker with Compose v2, curl, Python 3 and a terminal. Port 5432 must be free on your machine for Part 0. On Windows use WSL.

---

## Part 0 - The weekly deploy

Fork this repository, clone your fork and run:

```bash
./setup.sh
```

It starts the legacy database from `compose.legacy.yaml`, adds three polls, then does what the weekly deploy does: `docker compose down`, then `up`. It prints how many polls are left. Read `compose.legacy.yaml` while you are at it: count the things that are wrong with it (there are at least four).

---

## Act 1 - Where did the data go?

```bash
docker volume ls
docker volume ls -f dangling=true
docker inspect $(docker compose -f compose.legacy.yaml ps -q db) --format '{{json .Mounts}}' | python3 -m json.tool
```

The official `postgres` image declares `VOLUME /var/lib/postgresql/data`. When you do not mount something there yourself, Docker creates an **anonymous volume**, a 64-character-name directory, for every new container. `docker compose down` removed the container but not its volume; `up` created a **new** container with a **new** empty anonymous volume. The old one, with your polls, is still there. Docker calls it *dangling*.

> **Predict** Which of the volumes listed belongs to the container that is running now, and which one is the old one? Hint: inspect the running container and compare names.

**Recover the polls.** Do not mount the old volume into a running database and hope: work on a **copy**.

1. Make a copy: a new volume, and a throw-away container that mounts the old one **read-only** and the new one, and runs `cp -a`.
2. Start a temporary `postgres:16` on the copy (`-e POSTGRES_PASSWORD=pollie123`, a name like `voltmp`), wait for `pg_isready`, and dump the database with `pg_dump -U pollie -d pollie --clean --if-exists` into `backups/recovered.sql`.
3. Remove the temporary container and the copy.

Open `backups/recovered.sql`: your three polls are in it.

---

## Act 2 - The database, done right

Write `compose.yaml` (the comments list the requirements): project `pollie-db`, a **named volume** `pgdata`, the password from a file through a Compose **secret** and `POSTGRES_PASSWORD_FILE`, no published ports, a healthcheck, a restart policy. Create the secret file with a random password: it lives in `secrets/` and git ignores it.

```bash
openssl rand -hex 16 > secrets/db_password.txt
docker compose config          # read the final configuration: is the password visible?
docker compose up -d --wait
```

`--wait` returns when the healthcheck passes. Without a healthcheck it only waits for "started", which is not the same as "ready".

> **Think** Compare `docker inspect` of the legacy container (look at `Env`) with the new one. Who can read each password, and from where? How would the other containers of the application (the API, the worker) connect to this database without a published port?

---

## Part 3 - Backup and restore

Write `backup.sh` and `restore.sh` (see their comments). Rules for both: they run `pg_dump` and `psql` **inside** the container (the version always matches the server), they do not put the password on a command line, and they fail loudly when something is wrong.

```bash
./restore.sh backups/recovered.sql     # your rescued polls go into the new database
./backup.sh
docker compose down && docker compose up -d --wait      # a redeploy: do the polls survive?
docker compose down -v && docker compose up -d --wait   # the volume is destroyed: the database is empty
./restore.sh backups/pollie-<the file backup.sh printed>.sql
```

If the polls come back after the last command, you have a backup. If you have never run the restore, you have a hope.

> **Think** `docker compose down -v` deleted the data on purpose. What should have stopped you from typing it against a real database? Name two safeguards (backups, a different project name, labels, permissions).

---

## Part 4 - Prove it

```bash
./verify.sh
```

It reads your rescued polls and `docker compose config`, then does the whole story to your database: start, restore, back up, redeploy, destroy the volume, restore. Fix what is red and run it again until it ends with **ALL CHECKS PASSED**.

> **Stuck?** `--wait` times out: the healthcheck user or database name is wrong (`pg_isready -U pollie -d pollie`). `password authentication failed` after changing the secret: PostgreSQL only reads the password when it first creates its data directory, so remove the volume (`down -v`) and start again. `relation "polls" does not exist` on restore: the dump must contain the schema (`pg_dump` without `--data-only`). The dump file is empty: you ran `pg_dump` with `exec` but without `-T`, or the service is not up.

---

## Level up (optional)

- Run a `postgres:16` and a `postgres:17` against the same volume. What happens, and why can a dump/restore cross versions when the files cannot?
- Make the backup run every night in a second container with `cron` and keep seven days. Where do the backups go if the host disk dies?
- Use a **bind mount** for `./backups` instead of the host directory trick, and meet the permission problem (the postgres user inside the container is not you). How do you solve it?
- Add `tmpfs` for `/tmp` and run the container with `read_only: true`. What breaks first, and what does PostgreSQL need to write?

<!-- teardown:start (generated by labs.py, do not edit) -->
## Tear down (mandatory)

Resources left behind cost money, keep doors open and pollute the next lab. Removing what you created is part of the job, so it is part of the submission: **you must prove it is gone**.

Do this **last**, after you have pasted your `verify` output into `SUBMISSION.md` (once you tear down, the lab can no longer be verified).

1. Run `./teardown.sh`. It removes the containers and volumes of the lab (including the old orphaned one) and the generated files.

Then run the proof:

```bash
./verify-teardown.sh
```

It prints a list of checks and must end with **TEARDOWN VERIFIED**. If it reports leftovers, remove them and run it again. Paste the full output in your submission.
<!-- teardown:end -->

<!-- submission:start (generated by labs.py, do not edit) -->
## Submission

Answer the questions in `SUBMISSION.md` in **your fork** (paste output in code blocks where asked), push, then submit the **URL of your fork**.

**Files to commit**

- `compose.yaml`: PostgreSQL with a named volume and a secret
- `backup.sh` and `restore.sh`
- `backups/recovered.sql`: the polls you rescued

**Questions to answer**

1. Paste `docker volume ls` before and after the redeploy. Where was the data after the redeploy, and what is the difference between an anonymous volume and a named one? Why does `docker compose down` not delete it but a new `up` ignores it?
2. Paste the commands you used to recover the polls from the orphaned volume without touching it more than necessary. Why mount it read-only first?
3. Paste your `compose.yaml`. Where does the password live, how does the container read it (`POSTGRES_PASSWORD_FILE`), and why is a password in `environment:` worse? Where would it be visible (`docker inspect`, `docker compose config`)?
4. Why is the database port not published to the host in your setup, and how do the other containers reach it? What would publishing it as `5432:5432` change on a laptop in a coffee shop?
5. Explain named volume, bind mount and tmpfs in two lines each, and say which one you would use for: the database files, a config file you edit, a scratch directory for secrets.
6. Paste the output of `./backup.sh` and `./restore.sh`. A backup you have never restored is a hope. How did you prove that yours restores into an empty database?
7. Paste the output of `./verify.sh`. It must end with **ALL CHECKS PASSED**.
8. **Tear down.** Paste the output of `./verify-teardown.sh`. It must end with **TEARDOWN VERIFIED**.
<!-- submission:end -->
