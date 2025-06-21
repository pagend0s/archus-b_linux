#!/usr/bin/bash

echo -e ${CYAN}"Now entering section where: help scripts are copied to extracted bootstrap, mounting points are created."${NC}
sleep 3

sed -i '/## '$country_name'/,/## /{/https/s/#//g; /## /!p  }' "$script_dir/resources/Files/arch_chroot/root.x86_64/etc/pacman.d/mirrorlist" ##CHANGE COUNTRY !!!
cp "$script_dir/resources/scripts/in_chroot.sh" "$script_dir/resources/Files/arch_chroot/root.x86_64/home/"
cp "$script_dir/resources/scripts/in_chroot2.sh" "$script_dir/resources/Files/arch_chroot/root.x86_64/home/"
cp "$script_dir/resources/scripts/umount_jail.sh" "$script_dir/resources/Files/arch_chroot/root.x86_64/home/"
cp "$script_dir/resources/scripts/Error_handling/pacman_retrying.sh" "$script_dir/resources/Files/arch_chroot/root.x86_64/home/"
cp -R "$script_dir/resources/scripts/ramroot_1.1" "$script_dir/resources/Files/arch_chroot/root.x86_64/home/"
#cp "$script_dir/resources/scripts/Error_handling/pacstrap_retrying.sh" "$script_dir/resources/Files/arch_chroot/root.x86_64/home/"

search="root_partition"
replace=$root_partition

search2="time_zone4arch"
replace2=$time_zone4arch
search3="keyboard_layout"
replace3=$keyboard_layout

search4="esp_partition"
replace4=$esp_partition

sed -i "s|$search|$replace|g" "$script_dir/resources/Files/arch_chroot/root.x86_64/home/in_chroot.sh"
sed -i "s|$search2|$replace2|g" "$script_dir/resources/Files/arch_chroot/root.x86_64/home/in_chroot2.sh"
sed -i "s|$search3|$replace3|g" "$script_dir/resources/Files/arch_chroot/root.x86_64/home/in_chroot2.sh"
sed -i "s|$search4|$replace4|g" "$script_dir/resources/Files/arch_chroot/root.x86_64/home/in_chroot2.sh"

chmod +x "$script_dir/resources/Files/arch_chroot/root.x86_64/home/in_chroot.sh"
chmod +x "$script_dir/resources/Files/arch_chroot/root.x86_64/home/in_chroot2.sh"
chmod +x "$script_dir/resources/Files/arch_chroot/root.x86_64/home/pacman_retrying.sh"

echo "/home/in_chroot.sh && exit" >> "$script_dir/resources/Files/arch_chroot/root.x86_64/etc/bash.bashrc"

sudo cp /etc/resolv.conf  "$script_dir/resources/Files/arch_chroot/root.x86_64/etc/"

if ! sudo mount --make-rprivate /dev/;
then
        echo -e ${RED}"mount --make-rprivate /dev/ FAILED.."${NC}
else
	echo -e ${GREEN}"mount --make-rprivate /dev/ Successfull."${NC}
fi

if ! sudo mount --make-rprivate /dev/pts;
then
        echo -e ${RED}"mount --make-rprivate /dev/pts FAILED.."${NC}
else
	echo -e ${GREEN}"mount --make-rprivate /dev/pts Successfull."${NC}
fi

if ! sudo mount --make-rprivate /run/;
then
        echo -e ${RED}"mount --make-rprivate /run FAILED.."${NC}
else
	echo -e ${GREEN}"mount --make-rprivate /run Successfull."${NC}
fi

cd $script_dir/resources/Files/arch_chroot/root.x86_64/
echo -e ${CYAN}"mount --bind /root.x86_64/ --> root.x86_64/ is executed."${NC}
TARGET="$script_dir/resources/Files/arch_chroot/root.x86_64/"
SOURCE="$script_dir/resources/Files/arch_chroot/root.x86_64/"
if ! findmnt -rno TARGET "$TARGET" > /dev/null; 
then
        echo -e ${CYAN}"Mounting $SOURCE TO $TARGET"${NC}
        if ! sudo mount --bind "$SOURCE" "$TARGET";
        then
        	echo -e ${RED}"Mounting root.x86_64 --> root.x86_64 FAILED.."${NC}
        else
        	echo -e ${GREEN}"Mounting root.x86_64 --> root.x86_64 Successfull."${NC}
        	#mount_array+=("$TARGET")
        fi
else
        echo -e ${YELLOW}"$TARGET IS ALREADY MOUNTED"${NC}
fi
sleep 2 

TARGET="$script_dir/resources/Files/arch_chroot/root.x86_64/dev";
SOURCE="/dev"
echo -e ${CYAN}"sudo mount --rbind $SOURCE $TARGET"${NC}
if ! findmnt -rno TARGET "$TARGET" > /dev/null; 
then
        echo -e ${CYAN}"Mounting $SOURCE TO $TARGET"${NC}
        if ! sudo unshare mount --rbind "$SOURCE" "$TARGET";
        then
        	echo -e ${RED}"Mounting $SOURCE --> $TARGET FAILED.."${NC}
        else
        	echo -e ${GREEN}"Mounting $SOURCE --> $TARGET Successfull."${NC}
        	#mount_array+=("$TARGET")
        fi
else
        echo -e ${YELLOW}"$TARGET IS ALREADY MOUNTED"${NC}
fi
sleep 2 

TARGET="$script_dir/resources/Files/arch_chroot/root.x86_64/dev/pts/"
SOURCE="/dev/pts"
echo -e ${CYAN}"sudo mount -t devpts -o gid=5,mode=620 $SOURCE $TARGET"${NC}
if ! findmnt -rno TARGET "$TARGET" > /dev/null; 
then
        echo -e ${CYAN}"Mounting $SOURCE TO $TARGET"${NC}
        if ! sudo unshare mount -t devpts -o gid=5,mode=620 "$SOURCE" "$TARGET";
        then
        	echo -e ${RED}"Mounting $SOURCE --> $TARGET FAILED.."${NC}
        else
        	echo -e ${GREEN}"Mounting $SOURCE --> $TARGET Successfull."${NC}
        	#mount_array+=("$TARGET")
        fi
else
        echo -e ${YELLOW}"$TARGET IS ALREADY MOUNTED"${NC}
fi
sleep 2 

TARGET="$script_dir/resources/Files/arch_chroot/root.x86_64/proc"
SOURCE="/proc"
echo -e ${CYAN}"sudo mount -t proc $SOURCE $TARGET"${NC}
if ! findmnt -rno TARGET "$TARGET" > /dev/null; 
then
        echo -e ${CYAN}"Mounting $SOURCE TO $TARGET"${NC}
        if ! sudo mount -t proc "$SOURCE" "$TARGET";
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


TARGET="$script_dir/resources/Files/arch_chroot/root.x86_64/sys"
SOURCE="/sys"
echo -e ${CYAN}"sudo mount --rbind $SOURCE $TARGET"${NC}
if ! findmnt -rno TARGET "$TARGET" > /dev/null; 
then
        echo -e ${CYAN}"Mounting $SOURCE TO $TARGET"${NC}
        if ! sudo mount --rbind "$SOURCE" "$TARGET";
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

TARGET="$script_dir/resources/Files/arch_chroot/root.x86_64/run"
SOURCE="/run"
echo -e ${CYAN}"sudo mount --rbind $SOURCE $TARGET"${NC}
if ! findmnt -rno TARGET "$TARGET" > /dev/null; 
then
        echo -e ${CYAN}"Mounting $SOURCE TO $TARGET"${NC}
        if ! sudo mount --rbind "$SOURCE" "$TARGET";
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
sudo chroot . /bin/bash

sleep 2 
cd /

for (( i=${#mount_array[@]}-1; i>=0; i-- ));
do
        if ! sudo umount -l "${mount_array[i]}";
        then
        	echo -e ${RED}"umount "${mount_array[i]}" failed."${NC}
        else
        	echo -e ${GREEN}"umount "${mount_array[i]}" Successfull."${NC}
        fi
done

if ! sudo umount -l "$script_dir/resources/Files/arch_chroot/root.x86_64/";
then
	echo -e ${RED}"umount arch_chroot/root.x86_64/ FAILED.."${NC}
else
	echo -e ${GREEN}"umount arch_chroot/root.x86_64/ Successfull."${NC}
fi

if ! sudo rm -Rf $script_dir/resources/Files/{*,.*};
then
        	echo -e ${RED}"rm files from $script_dir/resources/Files/* Failed."${NC}
        else
        	echo -e ${GREEN}"rm files from $script_dir/resources/Files/* Successfull."${NC}
fi

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







