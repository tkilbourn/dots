#!/bin/sh
# Login reminder for the first-login steps bootstrap.sh cannot do for you.
# bootstrap.sh installs it as /etc/update-motd.d/99-dev-todo with @USER@
# filled in. Each line disappears once its step is done; with nothing left it
# prints nothing. Runs as root at every SSH login, so keep it to file checks.

user=@USER@
home=$(getent passwd "$user" | cut -d: -f6)

todo=""
add() { todo="$todo    $1\n"; }

grep -qs '^github.com:' "$home/.config/gh/hosts.yml" ||
    add "gh auth login -h github.com -p https -w </dev/null    # GitHub sign-in; open the URL it prints on your laptop"
[ -e /var/run/reboot-required ] &&
    add "sudo reboot                                           # finish the package upgrade"

[ -n "$todo" ] || exit 0
printf '\n  Server setup still to do:\n%b' "$todo"
