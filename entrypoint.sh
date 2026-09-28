#!/bin/bash
set -euo pipefail

HOME_DIR=/home/dev
KEY_DIR="$HOME_DIR/.acx/hostkeys"

if [ ! -f "$HOME_DIR/.dev-seeded" ]; then
  cp -a /etc/acx-skel/. "$HOME_DIR/"
  mkdir -p "$HOME_DIR/workspace"
  chown -R dev:dev "$HOME_DIR"
  touch "$HOME_DIR/.dev-seeded"
  chown dev:dev "$HOME_DIR/.dev-seeded"
  echo "home volume seeded"
fi
# A freshly created volume mounts with a root-owned root directory.
chown dev:dev "$HOME_DIR"

# Host keys live on the volume so they survive container recreation and keep
# matching the HostKeyAlias entry in known_hosts; root-owned so dev cannot read them.
mkdir -p "$KEY_DIR"
chown root:root "$HOME_DIR/.acx" "$KEY_DIR"
chmod 0700 "$HOME_DIR/.acx"
[ -f "$KEY_DIR/ssh_host_ed25519_key" ] || ssh-keygen -q -t ed25519 -N '' -f "$KEY_DIR/ssh_host_ed25519_key"

if [ -n "${SSH_PUBKEY:-}" ]; then
  install -d -m 0700 -o dev -g dev "$HOME_DIR/.ssh"
  touch "$HOME_DIR/.ssh/authorized_keys"
  grep -qxF "$SSH_PUBKEY" "$HOME_DIR/.ssh/authorized_keys" || echo "$SSH_PUBKEY" >> "$HOME_DIR/.ssh/authorized_keys"
  chown dev:dev "$HOME_DIR/.ssh/authorized_keys"
  chmod 0600 "$HOME_DIR/.ssh/authorized_keys"
fi

mkdir -p /run/sshd
/usr/sbin/sshd -e
echo "sshd listening on :22"

exec gosu dev sleep infinity
