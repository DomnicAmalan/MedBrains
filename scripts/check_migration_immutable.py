#!/usr/bin/env python3
"""
Migration files may be added. They may never be modified.

sqlx stores a checksum of each migration it applies and refuses to start when
the file on disk no longer matches. A comment, a reformat, a fixed typo — any
byte — stops every database that already ran it from booting the next build.
This compares every migration in the working tree against the version on
`origin/master`: a file that exists there and differs here fails.

  python3 scripts/check_migration_immutable.py            # against origin/master
  python3 scripts/check_migration_immutable.py --base HEAD~1
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
MIGRATIONS = Path("medbrains/crates/medbrains-db-migrations/src/migrations")


def git(*args: str) -> str:
    return subprocess.run(["git", *args], cwd=REPO_ROOT, capture_output=True, text=True, check=False).stdout


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default="origin/master")
    args = ap.parse_args()

    if not git("rev-parse", "--verify", args.base).strip():
        print(f"base {args.base} not found — fetch first, or pass --base", file=sys.stderr)
        return 2

    on_base = set(git("ls-tree", "-r", "--name-only", args.base, "--", MIGRATIONS.as_posix()).split())
    changed = [
        line
        for line in git("diff", "--name-only", args.base, "--", MIGRATIONS.as_posix()).split()
        if line in on_base and (REPO_ROOT / line).exists()
    ]
    if changed:
        print(f"{len(changed)} applied migration(s) modified — sqlx will refuse to start:")
        for path in changed:
            print(f"  ✗ {path}")
        print("\nA migration already on master is immutable. Write a new migration instead.")
        return 1
    print(f"✓ no migration on {args.base} has been modified")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
