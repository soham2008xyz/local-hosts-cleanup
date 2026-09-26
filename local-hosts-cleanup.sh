#!/bin/bash
# Remove the /etc/hosts entries that Local (localwp.com) adds, once Local has quit.
#
# Local rewrites its block on every launch, so removing it here is safe. We drop
# the same lines Local's own updateHostsFileWorker drops: any "#Local Site" line
# and the "## Local - Start ##" / "## Local - End ##" markers. Nothing else changes.
#
# Usage: local-hosts-cleanup.sh [hosts-file]   (default /etc/hosts)

set -euo pipefail

hosts="${1:-${HOSTS_FILE:-/etc/hosts}}"

# Local is still running: leave its entries alone.
if pgrep -xq Local; then
    exit 0
fi

if ! grep -qE '#Local Site|^## Local - (Start|End) ##$' "$hosts"; then
    exit 0
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

# grep -v exits 1 when no lines survive; that is not an error here.
grep -vE '#Local Site|^## Local - (Start|End) ##$' "$hosts" > "$tmp" || [ $? -eq 1 ]

# Local puts a blank line before its block; drop trailing blank lines it leaves.
printf '%s\n' "$(cat "$tmp")" > "$tmp"

if cmp -s "$tmp" "$hosts"; then
    exit 0
fi

removed=$(( $(wc -l < "$hosts") - $(wc -l < "$tmp") ))

# Write in place so the file keeps its owner, mode and inode.
cat "$tmp" > "$hosts"

if [ "$hosts" = /etc/hosts ]; then
    dscacheutil -flushcache
    killall -HUP mDNSResponder 2>/dev/null || true
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') removed ${removed} Local lines from ${hosts}"
