#!/usr/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

PACKAGES=("$@")
MAX_RETRIES=5
RETRY_COUNT=0
echo -e ${CYAN}"Installing packages: ${PACKAGES[*]}"${NC}

while ((RETRY_COUNT < MAX_RETRIES )); do
	pacman -Syu --noconfirm "${PACKAGES[@]}" && break
	echo -e ${RED}"Download failed. Retrying with next mirror..."${NC}
	pacman-mirrors --fasttrack 5 && pacman -Syy
((RETRY_COUNT++))
done

if (( RETRY_COUNT == MAX_RETRIES )); then
	echo -e ${RED}"Failed to install packages after $MAX_RETRIES attempts."${NC}
	exit 1
else
	echo -e ${GREEN}"Packages installed successfully"${NC}
fi
