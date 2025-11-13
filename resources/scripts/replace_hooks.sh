#!/usr/bin/bash

# Desired HOOKS value (edit to your needs)
NEW='HOOKS=(base udev keyboard autodetect modconf block filesystems fsck)'

# 1) Backup
cp -a /mnt/etc/mkinitcpio.conf /mnt/etc/mkinitcpio.conf.bak.$(date +%F_%H%M%S)

# 2) Replace the first non-comment HOOKS= line
sed -i -E "0,/^[[:space:]]*HOOKS[[:space:]]*=/{
  /^[[:space:]]*#/! s|^[[:space:]]*HOOKS[[:space:]]*=.*$|$NEW|
}" /mnt/etc/mkinitcpio.conf

# 3) Verify
grep -E '^[[:space:]]*HOOKS[[:space:]]*=' /mnt/etc/mkinitcpio.conf
