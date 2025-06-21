#!/usr/bin/bash
 
#script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: '
sudo umount -l "$script_dir/resources/Files/arch_chroot/root.x86_64/run"
sleep 2 
sudo umount -l "$script_dir/resources/Files/arch_chroot/root.x86_64/dev/pts"
sleep 2 
sudo umount -l "$script_dir/resources/Files/arch_chroot/root.x86_64/dev"
sleep 2 
sudo umount -l -"$script_dir/resources/Files/arch_chroot/root.x86_64/sys"
sleep 2 
sudo umount -l "$script_dir/resources/Files/arch_chroot/root.x86_64/proc"
sleep 2
sudo umount -R "$script_dir/resources/Files/arch_chroot/root.x86_64/"
'



umount -l /dev/pts
sleep 2
umount -l /dev
sleep 2 
umount -l /sys
sleep 2 
umount -l /proc
sleep 2


