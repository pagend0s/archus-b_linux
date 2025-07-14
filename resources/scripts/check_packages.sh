#!/bin/bash
echo -e ${CYAN}"Need to check the necessary binaries and internet ;)."${NC}

if ping -c 1 8.8.8.8 > /dev/null 2>&1; 
then
	echo -e  ${GREEN}"${bold}Internet is ON ;)"${NC}
else
	echo -e  ${RED}"${bold}ERROR ! No internet connection detected :("${NC}
	exit 1
fi	
sleep 1
if ! command -v parted &> /dev/null;
then
	echo -e  ${YELLOW}"parted is not installed. Installing.."${NC}
	sudo apt update
	sudo apt install -y parted
else
	echo -e  ${CYAN}"parted is already installed"${NC}
fi
sleep 1
if ! command -v mkfs.fat &> /dev/null;
then
	echo -e  ${YELLOW}"mkfs.fat is not installed. Installing.."${NC}
	sudo apt update
	sudo apt install -y dosfstools
else
	echo -e  ${CYAN}"mkfs.fat is already installed"${NC}
fi


if ! command -v fatlabel &> /dev/null;
then
	echo -e  ${YELLOW}"fatlabel is not installed. Installing.."${NC}
	sudo apt update
	sudo apt install -y fatlabel
else
	echo -e  ${CYAN}"fatlabel is already installed"${NC}
fi
sleep 1

if ! command -v e2label &> /dev/null;
then
	echo -e  ${YELLOW}"e2label is not installed. Installing.."${NC}
	sudo apt update
	sudo apt install -y e2label
else
	echo -e  ${CYAN}"e2label is already installed"${NC}
fi
sleep 1

if ! command -v curl &> /dev/null;
then
	echo -e  ${YELLOW}"curl is not installed. Installing.."${NC}
	sudo apt update
	sudo apt install -y curl
else
	echo -e  ${CYAN}"curl is already installed"${NC}
fi
sleep 1

if ! command -v wget &> /dev/null;
then
	echo -e  ${YELLOW}"wget is not installed. Installing.."${NC}
	sudo apt install -y wget

else
	echo -e ${CYAN}"wget is already installed"${NC}
fi

sleep 1
if ! command -v gpg &> /dev/null;
then
	echo -e  ${YELLOW}"gpg is not installed. Installing.."${NC}
	sudo apt update
	sudo apt install -y gnupg
else
	echo -e  ${CYAN}"gpg is already installed"${NC}
fi
sleep 1
if ! command -v zstd &> /dev/null;
then
	echo -e  ${YELLOW}"zstd is not installed. Installing.."${NC}
	sudo apt update
	sudo apt install -y zstd
else
	echo -e  ${CYAN}"zstd is already installed"${NC}
fi






