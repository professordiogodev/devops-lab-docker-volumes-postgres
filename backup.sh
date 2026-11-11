#!/usr/bin/env bash
# TODO: write a dump of the pollie database to backups/pollie-<timestamp>.sql using pg_dump INSIDE the db container
#       (docker compose exec -T db pg_dump ...). Options that matter: --clean --if-exists (so the dump can be restored over
#       an existing database), no password on the command line. Print the file name. Exit non-zero if the dump is empty.
