# local-hosts-cleanup

[Local](https://localwp.com) adds a line to `/etc/hosts` for every site you have, pointing each domain at your Mac. It never removes them when it quits, so real domains keep resolving to `127.0.0.1` after Local has closed.

This macOS LaunchDaemon removes those lines once Local has quit.

## How it works

Every 20 seconds, and at boot, launchd runs `local-hosts-cleanup.sh` as root. If no `Local` process is running, the script removes:

- every line containing `#Local Site`
- the `## Local - Start ##` and `## Local - End ##` markers

It then clears the DNS cache. It leaves the rest of `/etc/hosts` as it is and writes to the file only when something needs removing. These are the same lines Local itself deletes before it writes its block, so Local puts them all back the next time it starts.

It checks on a timer instead of waiting for Local to quit, so it also cleans up after a crash, a force-quit or a reboot.

## Install

```bash
git clone git@github.com:soham2008xyz/local-hosts-cleanup.git
cd local-hosts-cleanup
sudo ./install.sh
```

`install.sh`:

1. backs up `/etc/hosts` to `/etc/hosts.bak.<timestamp>`
2. copies the script to `/Library/PrivilegedHelperTools/local-hosts-cleanup`, owned by `root:wheel`
3. copies the plist to `/Library/LaunchDaemons/`
4. loads the daemon

The script must be owned by root so that no one else can edit a file that runs as root. To deploy changes, edit the script here and run `sudo ./install.sh` again.

## Check it works

```bash
sudo launchctl print system/local-hosts-cleanup | grep -E 'state|last exit'
```

Between runs this shows `state = not running`. That is expected, since each run takes well under a second. `last exit code = 0` means the last run succeeded.

The script writes a line to `/var/log/local-hosts-cleanup.log` only when it removes something:

```bash
cat /var/log/local-hosts-cleanup.log
```

## Uninstall

```bash
sudo ./uninstall.sh
```

This stops the daemon and deletes the two installed files. Your `/etc/hosts` backups stay where they are.

## Things to know

- **Local asks for your password every time it starts.** Local writes its block whenever the file doesn't already hold its exact list of entries. Since this tool removes that list, Local has to put it back on each launch, and writing `/etc/hosts` needs admin rights.
- **Cleanup starts only once the `Local` process exits.** Closing Local's window while the app keeps running in the Dock does nothing. Quit it with ⌘Q.
- **Cleanup takes up to 20 seconds** after Local quits. To change this, edit `StartInterval` in the plist and reinstall.
