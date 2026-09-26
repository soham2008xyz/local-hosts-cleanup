#!/bin/bash
# Install the cleanup as a root LaunchDaemon. Run with sudo.
set -euo pipefail

label=local-hosts-cleanup
here="$(cd "$(dirname "$0")" && pwd)"
bin="/Library/PrivilegedHelperTools/${label}"
plist="/Library/LaunchDaemons/${label}.plist"

if [ "$(id -u)" -ne 0 ]; then
    echo "Run with sudo: sudo $0" >&2
    exit 1
fi

cp -p /etc/hosts "/etc/hosts.bak.$(date +%Y%m%d%H%M%S)"

launchctl bootout "system/${label}" 2>/dev/null || true

install -o root -g wheel -m 755 "${here}/local-hosts-cleanup.sh" "$bin"
install -o root -g wheel -m 644 "${here}/${label}.plist" "$plist"

launchctl bootstrap system "$plist"

echo "Installed ${label}. Log: /var/log/local-hosts-cleanup.log"
