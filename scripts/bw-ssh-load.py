#!/usr/bin/env python3
import argparse
import json
import os
import subprocess
import sys
from typing import Iterable


def run(cmd: list[str], *, env: dict[str, str] | None = None, input_text: str | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        cmd,
        env=env,
        input=input_text,
        text=True,
        capture_output=True,
    )


def die(msg: str, code: int = 1) -> "None":
    print(f"error: {msg}", file=sys.stderr)
    raise SystemExit(code)


def ensure_cmd(name: str) -> None:
    if subprocess.run(["bash", "-lc", f"command -v {name}"], capture_output=True).returncode != 0:
        die(f"required command not found: {name}")


def ensure_bw_session(env: dict[str, str]) -> dict[str, str]:
    status = run(["bw", "status"]) 
    if status.returncode != 0:
        die(status.stderr.strip() or status.stdout.strip() or "failed to query bw status")

    state = json.loads(status.stdout).get("status")
    if state == "unauthenticated":
        die("Bitwarden CLI is not logged in. Run: bw login")

    if env.get("BW_SESSION"):
        return env

    print("Unlocking Bitwarden CLI...", file=sys.stderr)
    unlock = run(["bw", "unlock", "--raw"])
    if unlock.returncode != 0:
        die(unlock.stderr.strip() or unlock.stdout.strip() or "bw unlock failed")

    session = unlock.stdout.strip()
    if not session:
        die("bw unlock returned an empty session token")

    env = env.copy()
    env["BW_SESSION"] = session
    return env


def load_items(env: dict[str, str], search: str | None) -> list[dict]:
    cmd = ["bw", "list", "items"]
    if search:
        cmd += ["--search", search]
    result = run(cmd, env=env)
    if result.returncode != 0:
        die(result.stderr.strip() or result.stdout.strip() or "failed to list Bitwarden items")
    return json.loads(result.stdout)


def select_ssh_items(items: Iterable[dict], ids: set[str]) -> list[dict]:
    selected = []
    for item in items:
        ssh_key = item.get("sshKey") or {}
        private_key = ssh_key.get("privateKey")
        if not private_key:
            continue
        if ids and item.get("id") not in ids:
            continue
        selected.append(item)
    return selected


def add_key(item: dict, env: dict[str, str], ttl: int | None) -> None:
    name = item.get("name", "<unnamed>")
    item_id = item.get("id", "<no-id>")
    private_key = item["sshKey"]["privateKey"]

    cmd = ["ssh-add"]
    if ttl is not None:
        cmd += ["-t", str(ttl)]
    cmd.append("-")

    result = run(cmd, env=env, input_text=private_key)
    if result.returncode != 0:
        die(f"failed to add key for '{name}' ({item_id}): {(result.stderr or result.stdout).strip()}")
    print(f"loaded: {name} ({item_id})")


def main() -> None:
    parser = argparse.ArgumentParser(description="Load Bitwarden SSH keys into the active ssh-agent.")
    parser.add_argument("--search", help="Filter Bitwarden items by search text before selecting SSH keys.")
    parser.add_argument("--id", action="append", default=[], help="Load only the specified Bitwarden item id. Can be used multiple times.")
    parser.add_argument("--ttl", type=int, help="Optional ssh-agent TTL in seconds (passed to ssh-add -t).")
    parser.add_argument("--list", action="store_true", help="List matching Bitwarden SSH-key items without loading them.")
    parser.add_argument("--sync", action="store_true", help="Run 'bw sync' before listing items.")
    args = parser.parse_args()

    ensure_cmd("bw")
    ensure_cmd("ssh-add")

    env = os.environ.copy()
    if not env.get("SSH_AUTH_SOCK"):
        die("SSH_AUTH_SOCK is not set. Start an ssh-agent first.")

    env = ensure_bw_session(env)

    if args.sync:
        sync = run(["bw", "sync"], env=env)
        if sync.returncode != 0:
            die(sync.stderr.strip() or sync.stdout.strip() or "bw sync failed")

    items = load_items(env, args.search)
    ssh_items = select_ssh_items(items, set(args.id))

    if not ssh_items:
        die("no matching Bitwarden SSH-key items found")

    if args.list:
        for item in ssh_items:
            print(f"{item.get('id')}\t{item.get('name', '<unnamed>')}")
        return

    for item in ssh_items:
        add_key(item, env, args.ttl)


if __name__ == "__main__":
    main()
