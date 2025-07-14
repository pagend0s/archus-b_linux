#!/usr/bin/bash
trap 'exit 0' INT

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'
YELLOW='\033[0;33m'
PURPLE='\033[1;35m'

echo -e ${GREEN}"YOU ARE NOW INSIDE CHROOT 1 !"${NC}
set -e 
pacman-key --init
pacman-key --populate archlinux
pacman -Syyu --noconfirm

echo -e ${GREEN}"INSTALLING BASE WITH PACMAN"${NC}
bash /home/pacman_retrying.sh base

if ! mount root_partition /mnt/;
then
	echo -e ${RED}"Mount Failed"${NC}
	exit 1
else
	echo -e ${GREEN}"$root_partition is mounted in /mnt/"${NC}
fi

MIRRORLIST="/etc/pacman.d/mirrorlist"

echo -e ${GREEN}"Installing packages: mnt/ base linux linux-firmware into mnt/"${NC}


cp "$MIRRORLIST" "${MIRRORLIST}.bak"

error=1

while [ "$error" -eq 1 ]; do
	echo -e ${CYAN}"Running PACSTRAP"${NC}
	function comment_top_mirror(){
		echo -e ${CYAN}"Commenting out the top mirror"${NC}
		sed -i '0,/^Server/s/^Server/#Server/' "$MIRRORLIST"
	}
	if ! pacstrap mnt/ base linux linux-firmware; 
	then
		echo -e ${RED}"pacstrap failed. Trying next mirror"
		if ! grep -q "^Server" "$MIRRORLIST";
		then
			echo -e ${RED}"No more active mirrors left. Exiting"${NC}
			error=1
		fi
		comment_top_mirror
	else
		echo -e ${GREEN}"INSTALLATION IS COMPLITED WITHOUT ERRORS"${NC}
		error=0
	fi
done
if ! genfstab -U mnt/ >> mnt/etc/fstab;
then
	echo -e ${RED}"Failed to generate fstab !"${NC}
	exit 1
else
	echo -e ${GREEN}"fstab is generetad successfully."${NC}
	echo -e ${YELLOW}"Checking fstab file."${NC}
	
	output=$(findmnt --verify -F mnt/etc/fstab 2>&1);
	
	parse_errors=$( echo "$output" | grep -oP '\d+(?= parse errors)')
	warnings=$( echo "$output" | grep -oP '\d+(?= warnings)')
	errors=$( echo "$output" | grep -oP '\d+(?= errors)')
	
	echo -e ${YELLOW}"Parse errors: ${parse_errors:-0}"${NC}
	echo -e ${YELLOW}"Warnings: ${warnings:-0}"${NC}
	echo -e ${RED}"Errors: ${errors:-0}"${NC}
	
	if [[ "$parse_errors" -gt 0 ]]; then
		echo -e ${YELLOW}"There are parse errors in fstab"${NC}
		findmnt --verify -F mnt/etc/fstab
		echo -e ${YELLOW}"HIT ENTER WHEN READY:"${NC}
		read
	elif [[ "$warnings" -gt 0 ]]; then
		echo -e ${YELLOW}"There are warnings in fstab"${NC}
		if echo $output | grep -iE "target specified more than once"; then
			echo -e ${YELLOW}"Double ROOT entry detected. Correcting."${NC}
			sed -i.bak '/\b0 2\b/ s/^/#/' /mnt/etc/fstab
		fi
	elif [[ "$errors" -gt 0 ]]; then
		findmnt --verify -F mnt/etc/fstab
		echo -e ${RED}"/mnt/etc/fstab VERIFICATION FAILED. PLEASE CHECK THE ABOVE ERRORS"${NC}
		echo -e ${YELLOW}"HIT ENTER WHEN READY:"${NC}
		read
		exit 1
	else
		echo -e ${GREEN}"ALL ENTRYS LOOKING GOOD."${NC}
	fi	
fi

cp home/pacman_retrying.sh /mnt/home/pacman_retrying.sh
cp home/in_chroot2.sh /mnt/home/in_chroot2.sh
cp /etc/resolv.conf /mnt/etc/resolv.conf
cp -R /home/ramroot_1.1 /mnt/home/ramroot_1.1
echo "/home/in_chroot2.sh && exit" >> /mnt/etc/bash.bashrc
echo -e ${CYAN}"cd /mnt/ is executed."${NC}
if ! cd /mnt/;
then
	echo -e ${RED}"Failed cd /mnt/."${NC}
else
	echo -e ${GREEN}"cd /mnt/ was successfull."${NC}
fi

mount_array=()

TARGET="/mnt/dev"
SOURCE="/dev"
echo -e ${CYAN}"mount --rbind $SOURCE $TARGET"${NC}
if ! findmnt -rno TARGET "$TARGET" > /dev/null; 
then
        echo -e ${CYAN}"Mounting $SOURCE TO $TARGET"${NC}
        if ! unshare mount --rbind "$SOURCE" "$TARGET";
        then
        	echo -e ${RED}"Mounting $SOURCE --> $TARGET FAILED.."${NC}
        else
        	echo -e ${GREEN}"Mounting $SOURCE --> $TARGET Successfull."${NC}
        	mount_array+=("$TARGET")
        fi
else
        echo -e ${YELLOW}"$TARGET IS ALREADY MOUNTED"${NC}
fi
sleep 2 

TARGET="/mnt/dev/pts"
SOURCE="/dev/pts"
echo -e ${CYAN}"mount -t devpts -o gid=5,mode=620 $SOURCE $TARGET"${NC}
if ! findmnt -rno TARGET "$TARGET" > /dev/null; 
then
        echo -e ${CYAN}"Mounting $SOURCE TO $TARGET"${NC}
        if ! unshare mount -t devpts -o gid=5,mode=620 "$SOURCE" "$TARGET";
        then
        	echo -e ${RED}"Mounting $SOURCE --> $TARGET FAILED.."${NC}
        else
        	echo -e ${GREEN}"Mounting $SOURCE --> $TARGET Successfull."${NC}
        	mount_array+=("$TARGET")
        fi
else
        echo -e ${YELLOW}"$TARGET IS ALREADY MOUNTED"${NC}
fi
sleep 2 

TARGET="/mnt/proc/"
SOURCE="/proc"
echo -e ${CYAN}"mount -t proc $SOURCE $TARGET"${NC}
if ! findmnt -rno TARGET "$TARGET" > /dev/null; 
then
        echo -e ${CYAN}"Mounting $SOURCE TO $TARGET"${NC}
        if ! mount -t proc "$SOURCE" "$TARGET";
        then
        	echo -e ${RED}"Mounting $SOURCE --> $TARGET FAILED.."${NC}
        else
        	echo -e ${GREEN}"Mounting $SOURCE --> $TARGET Successfull."${NC}
        	mount_array+=("$TARGET")
        fi
else
        echo -e ${YELLOW}"$TARGET IS ALREADY MOUNTED"${NC}
fi
sleep 2 

TARGET="/mnt/sys/"
SOURCE="/sys"
echo -e ${CYAN}"mount --rbind $SOURCE $TARGET"${NC}
if ! findmnt -rno TARGET "$TARGET" > /dev/null; 
then
        echo -e ${CYAN}"Mounting $SOURCE TO $TARGET"${NC}
        if ! mount --rbind "$SOURCE" "$TARGET";
        then
        	echo -e ${RED}"Mounting $SOURCE --> $TARGET FAILED.."${NC}
        else
        	echo -e ${GREEN}"Mounting $SOURCE --> $TARGET Successfull."${NC}
        	mount_array+=("$TARGET")
        fi
else
        echo -e ${YELLOW}"$TARGET IS ALREADY MOUNTED"${NC}
fi
sleep 2 

TARGET="/mnt/run"
SOURCE="/run"
echo -e ${CYAN}"mount --rbind $SOURCE $TARGET"${NC}
if ! findmnt -rno TARGET "$TARGET" > /dev/null; 
then
        echo -e ${CYAN}"Mounting $SOURCE TO $TARGET"${NC}
        if ! mount --rbind "$SOURCE" "$TARGET";
        then
        	echo -e ${RED}"Mounting $SOURCE --> $TARGET FAILED.."${NC}
        else
        	echo -e ${GREEN}"Mounting $SOURCE --> $TARGET Successfull."${NC}
        	mount_array+=("$TARGET")
        fi
else
        echo -e ${YELLOW}"$TARGET IS ALREADY MOUNTED"${NC}
fi

chroot . /bin/bash

echo -e ${PURPLE}"IT LOOKS LIKE EVERYTHING WENT SMOOTHLY. DO YOU WAN TO GO BACK TO DEBIAN ENV ?"${NC} 
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









