#!/usr/bin/bash
echo -e ${CYAN}"Now entering section where: extracting archlinux-bootstrap-x86_64.tar.zst"${NC}
sleep 3
mkdir "$script_dir/resources/Files/arch_chroot"

cd "$script_dir/resources/Files/"
arch_tar=$(ls | grep "archlinux" -i --include='*.zst' | grep -v "sig")

if ! tar -xf $arch_tar -C "$script_dir/resources/Files/arch_chroot/" --zstd --checkpoint=200 --checkpoint-action=dot;
then
	echo -e ${RED}"Extracting failed."${NC}
	exit 1
else
        echo -e ${GREEN}"Extracting successfull."${NC}
fi
