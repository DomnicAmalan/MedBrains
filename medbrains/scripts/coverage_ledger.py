#!/usr/bin/env python3
"""
Coverage ledger — what the e2e suites actually exercise, per module, computed.

Sibling of `authz_ledger.py`. Coverage is tracked, not remembered: a module is
not "tested" because someone wrote a spec for it once; it is tested when the
ledger, reading routes and specs from disk, says so.

Cells (per module = first segment after /api/):
  api.smoke      GET routes with a case in the generated smoke specs
  api.write      non-GET routes whose path a hand-written spec touches
  api.perm       routes whose path an rbac spec touches
  screens        <Route path> entries in App.tsx under this module's slug
  ui.touched     of those, paths a spec navigates to

Every count is a *path literal appearing in a spec*, so it is an upper bound
on real coverage and an honest floor for "nobody has looked". The header warns
when the generated smoke specs are older than the routes they were generated
from — the failure that let `make e2e-full` stay green against specs dated
18 May while the routes had moved to 58 other files.

  python3 scripts/coverage_ledger.py                 # table
  python3 scripts/coverage_ledger.py --module lab    # one module, with the uncovered paths
  python3 scripts/coverage_ledger.py --json
  python3 scripts/coverage_ledger.py --check         # ratchet against the baseline
  python3 scripts/coverage_ledger.py --update-baseline
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

MEDBRAINS = Path(__file__).resolve().parent.parent
REPO_ROOT = MEDBRAINS.parent
sys.path.insert(0, str(REPO_ROOT / "scripts"))

from check_api_contract import (  # noqa: E402  (repo-root script, imported for its extractors)
    backend_route_sources,
    extract_backend_endpoints,
    normalize_param_names,
)

E2E = MEDBRAINS / "apps" / "web" / "e2e"
SMOKE_DIR = E2E / "smoke" / "api"
APP_TSX = MEDBRAINS / "apps" / "web" / "src" / "App.tsx"
BASELINE = MEDBRAINS / "scripts" / "coverage_ledger.baseline.json"

RE_API_LITERAL = re.compile(r"""["'`](/api/[^"'`\s]*)["'`]""")
RE_TEMPLATE_SEG = re.compile(r"\$\{[^}]*\}")
# Generated smoke specs carry concrete seed values (a UUID, a number) where the
# route has {id}; fold those back so a route and its spec compare equal.
RE_CONCRETE_SEG = re.compile(r"/(?:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}|\d+)(?=/|$)")
RE_ROUTE_PATH = re.compile(r'<Route\s+path="([^"]+)"')
RE_GOTO = re.compile(r"""(?:goto|navigateTo)\(\s*(?:page\s*,\s*)?["'`](/[^"'`?\s]*)""")
CELLS = ("api.smoke", "api.write", "api.perm", "ui.touched")


def module_of(path: str) -> str:
    m = re.match(r"^/api/([A-Za-z0-9_-]+)", path)
    return m.group(1) if m else "_misc"


def norm(path: str) -> str:
    """Template segments → {_}, then the contract checker's own normaliser."""
    folded = RE_CONCRETE_SEG.sub("/{_}", RE_TEMPLATE_SEG.sub("{_}", path))
    return normalize_param_names(folded.rstrip("/"))


def spec_touches() -> tuple[set[str], set[str], set[str], set[str]]:
    """(paths in smoke specs, paths in hand-written specs, paths in rbac specs, screens navigated)."""
    smoke: set[str] = set()
    hand: set[str] = set()
    rbac: set[str] = set()
    screens: set[str] = set()
    for spec in E2E.rglob("*.spec.ts"):
        text = spec.read_text(errors="ignore")
        paths = {norm(p) for p in RE_API_LITERAL.findall(text)}
        rel = spec.relative_to(E2E).as_posix()
        if rel.startswith("smoke/api/"):
            smoke |= paths
        else:
            hand |= paths
            if rel.startswith("rbac/"):
                rbac |= paths
        screens |= {p.rstrip("/") or "/" for p in RE_GOTO.findall(text)}
    return smoke, hand, rbac, screens


def app_screens() -> dict[str, list[str]]:
    """App.tsx route paths grouped by their first segment (the module slug)."""
    out: dict[str, list[str]] = defaultdict(list)
    if not APP_TSX.exists():
        return out
    for path in RE_ROUTE_PATH.findall(APP_TSX.read_text()):
        if path in ("*", "") or ":" in path:
            continue
        full = path if path.startswith("/") else f"/{path}"
        out[full.split("/")[1] or "_root"].append(full)
    return out


def smoke_is_stale() -> bool:
    if not SMOKE_DIR.exists():
        return True
    newest_route = max((p.stat().st_mtime for p in backend_route_sources()), default=0.0)
    specs = list(SMOKE_DIR.glob("*.spec.ts"))
    if not specs:
        return True
    oldest_spec = min(p.stat().st_mtime for p in specs)
    return oldest_spec < newest_route


def build() -> dict:
    endpoints = extract_backend_endpoints()
    smoke, hand, rbac, navigated = spec_touches()
    screens = app_screens()

    modules: dict[str, dict] = {}
    for method, path, _line in endpoints:
        n = norm(path)
        m = modules.setdefault(
            module_of(path),
            {
                "get": set(), "get_smoke": set(),
                "write": set(), "write_hand": set(),
                "all": set(), "perm": set(),
            },
        )
        key = f"{method} {n}"
        m["all"].add(key)
        if n in rbac:
            m["perm"].add(key)
        if method == "GET":
            m["get"].add(key)
            if n in smoke:
                m["get_smoke"].add(key)
        else:
            m["write"].add(key)
            if n in hand:
                m["write_hand"].add(key)

    rows = []
    for name in sorted(set(modules) | set(screens)):
        m = modules.get(name)
        scr = screens.get(name, [])
        touched = [s for s in scr if s in navigated]
        rows.append(
            {
                "module": name,
                "routes": len(m["all"]) if m else 0,
                "get": len(m["get"]) if m else 0,
                "api.smoke": len(m["get_smoke"]) if m else 0,
                "write": len(m["write"]) if m else 0,
                "api.write": len(m["write_hand"]) if m else 0,
                "api.perm": len(m["perm"]) if m else 0,
                "screens": len(scr),
                "ui.touched": len(touched),
                "_uncovered_get": sorted(m["get"] - m["get_smoke"]) if m else [],
                "_uncovered_write": sorted(m["write"] - m["write_hand"]) if m else [],
                "_untouched_screens": sorted(set(scr) - set(touched)),
            }
        )
    return {
        "routes": len(endpoints),
        "screens": sum(len(v) for v in screens.values()),
        "smoke_stale": smoke_is_stale(),
        "rows": rows,
    }


def pct(part: int, whole: int) -> str:
    return "  -" if whole == 0 else f"{100 * part // whole:3d}"


def print_table(data: dict, only: str | None) -> None:
    rows = [r for r in data["rows"] if not only or r["module"] == only]
    if data["smoke_stale"]:
        print("WARNING: smoke specs are older than the routes — run `make e2e-smoke-generate`\n")
    print(
        f"COVERAGE LEDGER  routes {data['routes']}  screens {data['screens']}"
        "  (a cell = the path appears in a spec; an upper bound on real coverage)\n"
    )
    print(f"{'module':22} {'GET':>4} {'smoke%':>6} {'W':>4} {'write%':>6} {'perm':>5} {'scr':>4} {'touched%':>8}")
    for r in rows:
        print(
            f"{r['module']:22} {r['get']:4d} {pct(r['api.smoke'], r['get']):>6} "
            f"{r['write']:4d} {pct(r['api.write'], r['write']):>6} {r['api.perm']:5d} "
            f"{r['screens']:4d} {pct(r['ui.touched'], r['screens']):>8}"
        )
    tot = {k: sum(r[k] for r in data["rows"]) for k in ("get", "api.smoke", "write", "api.write", "api.perm", "screens", "ui.touched")}
    print(
        f"\n{'TOTAL':22} {tot['get']:4d} {pct(tot['api.smoke'], tot['get']):>6} "
        f"{tot['write']:4d} {pct(tot['api.write'], tot['write']):>6} {tot['api.perm']:5d} "
        f"{tot['screens']:4d} {pct(tot['ui.touched'], tot['screens']):>8}"
    )
    if only and rows:
        r = rows[0]
        for label, key in (
            ("GET routes with no smoke case", "_uncovered_get"),
            ("write routes no spec touches", "_uncovered_write"),
            ("screens no spec navigates to", "_untouched_screens"),
        ):
            print(f"\n{label} ({len(r[key])}):")
            for item in r[key][:60]:
                print(f"  {item}")
            if len(r[key]) > 60:
                print(f"  … {len(r[key]) - 60} more")


def counts(data: dict) -> dict[str, dict[str, int]]:
    return {r["module"]: {c: r[c] for c in CELLS} for r in data["rows"]}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--module")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--check", action="store_true", help="fail if any cell fell below the baseline")
    ap.add_argument("--update-baseline", action="store_true")
    args = ap.parse_args()

    data = build()
    if args.update_baseline:
        BASELINE.write_text(json.dumps(counts(data), indent=1, sort_keys=True) + "\n")
        print(f"baseline written: {BASELINE.relative_to(MEDBRAINS)}")
        return 0
    if args.check:
        if not BASELINE.exists():
            print("no baseline — run `make coverage-ledger-update-baseline` first", file=sys.stderr)
            return 2
        base = json.loads(BASELINE.read_text())
        now = counts(data)
        drops = [
            f"{mod}.{cell}: {base[mod][cell]} → {now.get(mod, {}).get(cell, 0)}"
            for mod in base
            for cell in CELLS
            if now.get(mod, {}).get(cell, 0) < base[mod].get(cell, 0)
        ]
        if data["smoke_stale"]:
            drops.append("smoke specs are older than the routes (run make e2e-smoke-generate)")
        if drops:
            print("coverage ratchet failed — these cells fell:")
            for d in drops:
                print(f"  ✗ {d}")
            return 1
        print("coverage ratchet: OK (no cell below baseline)")
        return 0
    if args.json:
        print(json.dumps({k: v for k, v in data.items()}, indent=1, default=list))
        return 0
    print_table(data, args.module)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
