#!/usr/bin/bash

TARGET="$1"
PACKAGES=("$@")
MAX_RETRIES=5
RETRY_COUNT=0

echo "Installing packages: ${PACKAGES[@]} into $TARGET"

while (( RETRY_COUNT < MAX_RETRIES )); do
	if pacstrap "$TARGET" "${PACKAGES[@]}"; then
		echo "Packages isntalled successfully."
		exit 0
	else
		echo "pacstrap failed. Retrying with updated mirrors..."
		reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
		((RETRY_COUNT++))
	fi
done

echo "FAILED to install packages after $MAX_RETRIES attempts."

exit 1
