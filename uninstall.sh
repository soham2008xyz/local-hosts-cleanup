#!/bin/bash
# Remove the cleanup LaunchDaemon. Run with sudo.
set -euo pipefail

label=local-hosts-cleanup

if [ "$(id -u)" -ne 0 ]; then
    echo "Run with sudo: sudo $0" >&2
    exit 1
fi

launchctl bootout "system/${label}" 2>/dev/null || true
rm -f "/Library/LaunchDaemons/${label}.plist" "/Library/PrivilegedHelperTools/${label}"

echo "Uninstalled ${label}."
