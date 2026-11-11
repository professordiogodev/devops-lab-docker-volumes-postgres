#!/usr/bin/env bash
# Reads your files, then redeploys your database, backs it up, destroys it and restores it. Run with: ./verify.sh
cd "$(dirname "$0")" || exit 1
[ -f .lab/.truth.json ] || { echo "Run ./setup.sh first." >&2; exit 1; }
exec python3 .lab/volcheck.py
