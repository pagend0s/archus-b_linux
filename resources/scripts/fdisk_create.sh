#!/usr/bin/bash

usb_mount_1=$(lsblk -d -o NAME,ROTA,SIZE | grep -v 0B |  grep -oP "s[a-z][a-z]?" | sort -u )

echo -e ${CYAN}"Entering Partition section."${NC}
sleep 3

for j in ${usb_mount_1[@]} ;
	do
		usb_mount_test=$(udevadm info --query=all -n /dev/"$j" 2>/dev/null | grep "USB" )
		if [[ -z "$usb_mount_test" ]] ;
			then
				:
			else
				usb_mount+=($j)
			fi
	done
if [[ -z "$usb_mount" ]]
		 then
		 	echo    "###############################"
		 	echo -e "#${PURPLE} THERE IS no USB... ${NC}         #"
		 	echo    "###############################"
		 	exit 1
	else
		# Separate mount point information for each disk
		for i in ${usb_mount[@]} ;
			do
		    		echo    "##################################################################################"
	            		echo -e "#${CYAN} ON THIS MASCHINE I HAVE DETECTED USB WITH MOUNTING POINT UNDER >>>>>>${PURPLE}/dev/"$i"${NC}  #" # Mount point
		    		echo    "##################################################################################"
			done
	fi
 
for_awk="$usb_mount"
usb_mount="/dev/$usb_mount"
echo -e "I have found USB at: ${RED}${bold}$usb_mount${NC} .. is this the correct mountpoint for USB ?"
sleep 1
echo ""
lsblk -o NAME,SIZE,LABEL | awk -v drive="$for_awk" '{
        if ($1 == drive)
                print "\033[0;31m" "\033[1m" $0, "<----------- THIS IS THE DRIVE WHERE ARCH WILL BE INSTALLED ------------" "\033[0m"
        else print $0
        }'
sleep 2
echo -e ${RED}${bold}
read -p "Continue ? ALL DATA WILL BE LOST ON THIS USB: (y/n)?" choice
echo -e ${NC} 
case "$choice" in
  y|Y ) echo "yes";;
  n|N ) echo "no";;
  * ) echo "invalid";;
esac

if [[ "$choice" == "n" ||  "$choice" == "N" ]]; then
	exit 1
elif [[ "$choice" == "y" ||  "$choice" == "yes" ||  "$choice" == "Y" ||  "$choice" == "YES" ]]; then 
		:
else
	exit 1
fi

to_umount=$(findmnt -no SOURCE,TARGET | grep $usb_mount | awk '{print $1}')
if [[ -z "$to_umount" ]];
then
	:
else
	echo -e ${YELLOW}"Partitions on $usb_mount are mounted. Umount in progress."${NC}
	for i in ${to_umount[@]};
	do	
		echo -e ${YELLOW}"$i Umount in progress."${NC}
		to_umount_point=$(findmnt -no TARGET -S $i )
		if ! sudo umount -l "$to_umount_point";
		then
			echo -e ${RED}"Failed to umount $i. Try to umount manual and run script again"${NC}
			exit 1
		else
			echo -e ${GREEN}"$i Umount successfull."${NC}
		fi
	done
fi

DEVICE="$usb_mount"
SIZE_BYTES=$(sudo blockdev --getsize64 "$DEVICE")

TRESHOLD=$((32 * 1024 *1024 * 1024))

if [[ "$SIZE_BYTES" -gt "$TRESHOLD" ]];
then
        echo -e ${RED}${bold}"The USB which is selected is unfortunately not suitable because it is larger than 32GB and FAT16 partition (uefi boot)" 
        echo -e "will not be recognize during boot, in other words, the disk must be less or equal 32 GB"{NC}
        exit 1
fi


esp_partition="$usb_mount""1"
root_partition="$usb_mount""2"

echo -e ${CYAN}"creating GPT partition table on $usb_mount"${NC}
if ! sudo parted -s $usb_mount mklabel gpt;
then
	echo -e ${RED}"Failed to create gpt $usb_mount."${NC}
        exit 1
fi
sleep 2

echo -e ${CYAN}"creating 1 GB esp for uefi boot on $usb_mount."${NC}
if ! sudo parted -s $usb_mount mkpart primary 1MB 1GB ;
then
        echo -e ${RED}"Failed to create Boot partition on $usb_mount."${NC}
        exit 1
else
        echo -e ${GREEN}"Boot on $usb_mount successfully created."${NC}

fi
sleep 2

echo -e ${CYAN}"creating root partition on $usb_mount"${NC}
if ! sudo parted -s $usb_mount mkpart primary 1GB 100% ;
then
	echo -e ${RED}"Failed to create Root partition on $usb_mount."${NC}
	exit 1
else
	echo -e ${GREEN}"Root on $usb_mount successfully created."${NC}
fi
sleep 2

echo -e ${CYAN}"setting boot and esp flag on $esp_partition"${NC}
sudo parted $usb_mount << EOF
set 1 boot on
set 1 esp on
quit
EOF
sleep 2

echo -e ${CYAN}"formating $esp_partition to FAT16 fs"${NC}
if ! sudo mkfs.fat -F 16 $esp_partition
then
	echo -e ${RED}"Failed to format $esp_partition to FAT16 fs."${NC}
	exit 1
else
	echo -e ${GREEN}"Format to FAT16 fs on $esp_partition successfull."${NC}

fi
sleep 2

echo -e ${CYAN}"formating $root_partition to ext4 fs."${NC}
if ! sudo mkfs.ext4 -F $root_partition
then
	echo -e ${RED}"Failed to format $root_partition to ext4 fs."${NC}
	exit 1
else
	echo -e ${GREEN}"Format to ext4 fs on $esp_partition successfull."${NC}

fi
sleep 2

sudo fatlabel $esp_partition "ARCHEFIBOOT"
sleep 1
sudo e2label $root_partition "ARCHROOT"

echo -e ${CYAN}
sudo parted "$usb_mount" << EOF
print free
quit
EOF
echo -e ${NC}
sleep 2

export root_partition
export esp_partition
