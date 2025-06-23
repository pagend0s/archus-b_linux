#!/usr/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'
YELLOW='\033[0;33m'
PURPLE='\033[1;35m'

echo -e ${GREEN}"YOU ARE NOW INSIDE CHROOT 2 !"${NC}

ln -s /usr/share/zoneinfo/time_zone4arch /etc/localtime
sed -i '/en_US.UTF-8 UTF-8 /{s/#//g; }' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=keyboard_layout" > /etc/vconsole.conf
echo "archUSB" > /etc/hostname
echo "SET PASSWORD FOR ROOT"
echo "root:qwertz" | chpasswd
bash /home/pacman_retrying.sh chntpw \
	exfat-utils \
	nano \
	ntfs-3g \
	nvme-cli \
	smartmontools \
	testdisk \
	sudo \
	grub \
	efibootmgr \
	cmatrix \
	rsync \
	networkmanager

search='HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)'
replace='HOOKS="base udev block filesystems"'

search2='MODULES=()'
replace2='MODULES="crc32 crc32c_generic crc32c crc32-generic"'

sed -i "s|$search|$replace|g" /etc/mkinitcpio.conf
sed -i "s|$search2|$replace2|g" /etc/mkinitcpio.conf

mkinitcpio -p linux

mkdir -p /mnt/esp/
mount esp_partition /mnt/esp/
grub-install --target=x86_64-efi --efi-directory=/mnt/esp/ --bootloader-id=GRUB --removable
grub-mkconfig -o /boot/grub/grub.cfg

search="/home/in_chroot2.sh && exit"
replace=""
sed -i "s|$search|$replace|g" /etc/bash.bashrc
echo "cmatrix" >> /etc/bash.bashrc
echo "echo 'To connect with with WiFi:' " >> /etc/bash.bashrc
echo "echo 'systemctl start NetworkManager' " >> /etc/bash.bashrc
echo "echo 'nmcli device wifi list' " >> /etc/bash.bashrc
echo "echo 'nmcli device wifi connect "'<SSID>'" password "'password'" ' " >> /etc/bash.bashrc

mkdir -p /etc/systemd/system/getty@tty1.service.d/
echo '[Service]' >> /etc/systemd/system/getty@tty1.service.d/override.conf
echo 'ExecStart=' >> /etc/systemd/system/getty@tty1.service.d/override.conf
echo 'ExecStart=-/usr/bin/agetty --autologin root --noclear %I $TERM' >> /etc/systemd/system/getty@tty1.service.d/override.conf

search2='GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"'
replace2='GRUB_CMDLINE_LINUX_DEFAULT="fsck.mode=skip quiet loglevel=0 rd.systemd.show_status=false nowatchdog mitigations=off libahci.ignore_sss=1"'
sed -i "s|$search2|$replace2|g" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

echo "blacklist iTCO_wdt" >> /etc/modprobe.d/blacklist.con
echo "blacklist pcspkr" >> /etc/modprobe.d/blacklist.con
echo "blacklist joydev" >> /etc/modprobe.d/blacklist.con
echo "blacklist mousedev" >> /etc/modprobe.d/blacklist.con
echo "blacklist mac_hid" >> /etc/modprobe.d/blacklist.con
echo "blacklist uvcvideo" >> /etc/modprobe.d/blacklist.con

search3='MODULES="crc32 crc32c_generic crc32c crc32-generic"'
replace3='MODULES=(zram ext4)'

sed -i "s|$search3|$replace3|g" /etc/mkinitcpio.conf

search4='HOOKS="base udev block filesystems"'
replace4='HOOKS=(base udev autodetect modconf keyboard block filesystems fsck)'

sed -i "s|$search4|$replace4|g" /etc/mkinitcpio.conf

sed -i.bak '/\bswap\b/ s/^/#/' /etc/fstab

cp -R /home/ramroot_1.1/usr/* /usr/
chmod -R 777 ./home/ramroot_1.1/

./home/ramroot_1.1/ramroot -C
if ! ./home/ramroot_1.1/ramroot -E;
then
        echo -e ${RED}"Failed to activate RAMROOT."${NC}
        echo -e ${CYAN}"Another attempt"${NC}
        search5='HOOKS=()'
	replace5='HOOKS=(base udev autodetect modconf keyboard block filesystems fsck)'
	chmod -R 777 ./home/ramroot_1.1/
	sed -i "s|$search4|$replace4|g" /etc/mkinitcpio.conf
	./home/ramroot_1.1/ramroot -C
        ./home/ramroot_1.1/ramroot -E
else
        echo -e ${GREEN}"RAMROOT IS ACTIVATED !"${NC}

fi

pacman -Scc --noconfirm

umount -l /mnt/esp/

echo -e ${PURPLE}"IT LOOKS LIKE EVERYTHING WENT SMOOTHLY. DO YOU WAN TO GO BACK TO THE PREVIOUSE chroot ENV ?"${NC} 
read -p "Continue (y/n)?" choice
case "$choice" in
  y|Y ) echo "yes";;
  n|N ) echo "no";;
  * ) echo "invalid";;
esac
if [[ "$choice" == "y" ||  "$choice" == "Y" ]]; 
	then
		echo "exit"
		exit
	else
		read -p "Press enter to continue or exit for EXIT chroot"
fi

bash
