#!/usr/bin/bash
echo -e ${CYAN}"Now entering section where: Setting up locale, source links for files, checking signatures."${NC}
sleep 3

unset $time_zone
unset $country_code
echo -e ${CYAN}"Downloading list world link list from  https://archlinux.org/download/"${NC}
curl --retry 5 --retry-delay 2 --retry-max-time 30 https://archlinux.org/download/ -o "$script_dir/resources/Files/links.html"
echo -e ${CYAN}"Setting locale: time zone, keyboard layout"${NC}
sleep 1
#CITY
time_zone=$(timedatectl status | grep "Time zone" | awk '{print $3}' | cut -d'/' -f2)
time_zone4arch=$(timedatectl status | grep "Time zone" | awk '{print $3}')
keyboard_layout=$(cat /etc/default/keyboard | grep XKBLAYOUT | grep -oP '"\K[^"]+(?=")')
export keyboard_layout
export time_zone4arch

echo -e ${CYAN}"Setting country code from zone.tab for identify download mirror"${NC}
sleep 1
#COUNTRY CODE
country_code=$(cat /usr/share/zoneinfo/zone.tab | grep $time_zone | awk '{print $1}')
if [ -z $country_code ]; then
	country_code="US"
fi

echo -e ${CYAN}"Setting country name for downloads mirror in pacmans mirrorlist"${NC}
sleep 1
#COUNTRY NAME
country_name=$(cat "$script_dir/resources/scripts/countrys.txt" | grep "$country_code" | awk '{print $2}')
export country_name

if [ -z $country_name ]; then
	country_name="United States"
fi

echo -e ${CYAN}"Setting mirrors for location: $country_name"${NC}
sleep 1
download_url=$(sed -n "/$country_name/,/h5/p" "$script_dir/resources/Files/links.html" | grep -Eo '(https)://[^/"]+' | head -n 1)

counter=1

bootstrap_source=$(echo "$download_url/archlinux/iso/latest/archlinux-bootstrap-x86_64.tar.zst")
echo -e ${CYAN}"Setting bootstrap tar.zst source to:  for location: $bootstrap_source"${NC}
sleep 1
bootstrap_source_sig=$(echo "$download_url/archlinux/iso/latest/archlinux-bootstrap-x86_64.tar.zst.sig")
echo -e ${CYAN}"Setting bootstrap signature source to:  for location: $bootstrap_source_sig"${NC}
sleep 1

echo -e ${CYAN}"Checking connection to: $bootstrap_source"${NC}
sleep 1
response_bootstrap_source=$(curl -s -o /dev/null -w "%{http_code}" -I $bootstrap_source)
if [ $? -ne 0 ]; then
	echo -e ${RED}"No response from: $bootstrap_source"${NC}	
	bootstrap_source2=$(echo "$download_url/pub/linux/archlinux/iso/latest/archlinux-bootstrap-x86_64.tar.zst")
	echo -e ${CYAN}"Checking connection to: $bootstrap_source2 after $bootstrap_source was failed."${NC}
	response_bootstrap_source=$(curl -s -o /dev/null -w "%{http_code}" -I $bootstrap_source2)
	if [ $? -ne 0 ]; then
		echo -e ${RED}"No response from: $bootstrap_source2"${NC}	
		response=0
	else
		bootstrap_source=$(echo $bootstrap_source2)
		echo -e ${CYAN}"Changing to $bootstrap_source"${NC}
	fi
else
	if [ "$response_bootstrap_source" -eq 200 ]; then
		echo -e ${GREEN}" $bootstrap_source is alive. Success"${NC}
		response=1
	else
		echo -e ${RED}"No response from: $response_bootstrap_source reason: $response_bootstrap_source "${NC} 
		bootstrap_source2=$(echo "$download_url/pub/linux/archlinux/iso/latest/archlinux-bootstrap-x86_64.tar.zst")
		echo -e ${CYAN}"Checking connection to: $bootstrap_source2 ."${NC}
		response_bootstrap_source=$(curl -s -o /dev/null -w "%{http_code}" -I $bootstrap_source2)
		if [ $? -ne 0 ]; then
			echo -e ${RED}"No response from: $bootstrap_source2 reason: $response_bootstrap_source"${NC}	
			response=0
		else
			bootstrap_source=$(echo $bootstrap_source2)
			echo -e ${GREEN}" $bootstrap_source is alive. Success"${NC}
			response=1
		fi
	fi
fi
echo -e ${CYAN}"Checking connection to: $bootstrap_source_sig ."${NC}
sleep 1
response_bootstrap_source_sig=$(curl -s -o /dev/null -w "%{http_code}" -I $bootstrap_source_sig)
if [ $? -ne 0 ]; then
	echo -e ${RED}"No response from: $bootstrap_source_sig ."${NC}
	bootstrap_source_sig2=$(echo "$download_url/pub/linux/archlinux/iso/latest/archlinux-bootstrap-x86_64.tar.zst.sig")
	echo -e ${CYAN}"Checking connection to: $bootstrap_source_sig2 after $bootstrap_source_sig ."${NC}
	response_bootstrap_source_sig=$(curl -s -o /dev/null -w "%{http_code}" -I $bootstrap_source_sig2)
	if [ $? -ne 0 ]; then
		echo -e ${RED}"No response from: $bootstrap_source_sig2"${NC}	
		response2=0
	else
		bootstrap_source_sig=$(echo $bootstrap_source_sig2)
		echo -e ${CYAN}"Changing to $bootstrap_source_sig2"${NC}
		response2=1
	fi

else
	if [ "$response_bootstrap_source_sig" -eq 200 ]; then
		echo -e ${GREEN}" $bootstrap_source_sig is alive. Success"${NC}
		response2=1
	else
		echo -e ${RED}"No response from: $bootstrap_source_sig reason: $response_bootstrap_source_sig"${NC} 
		bootstrap_source_sig2=$(echo "$download_url/pub/linux/archlinux/iso/latest/archlinux-bootstrap-x86_64.tar.zst.sig")
		echo -e ${CYAN}"Checking connection to: bootstrap_source_sig2 ."${NC}
		response_bootstrap_source_sig=$(curl -s -o /dev/null -w "%{http_code}" -I $bootstrap_source_sig2)
		if [ $? -ne 0 ]; then
			echo -e ${RED}"No response from: $bootstrap_source_sig2 reason: $response_bootstrap_source_sig "${NC}	
			response2=0
		else
			bootstrap_source_sig=$(echo $bootstrap_source_sig2)
			echo -e ${CYAN}"Changing to $bootstrap_source_sig"${NC}
			response2=1
		fi
	fi
fi

function other_source_when_error(){
	while [ $response -eq 0 ] || [ $response2 -eq 0 ] || [ $signature_error -eq 1 ];
		do
		signature_error=0
		((counter++))
		echo $counter
		download_url=$(sed -n "/$country_name/,/h5/p" "$script_dir/resources/Files/links.html" | grep -Eo '(https)://[^/"]+' | awk 'NR=='$counter'')
		echo -e ${CYAN}"Checking download URL: $download_url."${NC}
		bootstrap_source=$(echo "$download_url/archlinux/iso/latest/archlinux-bootstrap-x86_64.tar.zst")
		echo -e ${CYAN}"Checking connection to: $bootstrap_source"${NC}
		bootstrap_source_sig=$(echo "$download_url/archlinux/iso/latest/archlinux-bootstrap-x86_64.tar.zst.sig")
		response_bootstrap_source=$(curl -s -o /dev/null -w "%{http_code}" -I $bootstrap_source)
		if [ $? -ne 0 ]; then
			echo -e ${RED}"No response from: $bootstrap_source reason $response_bootstrap_source ."${NC}
			response=0
		else
			if [ "$response_bootstrap_source" -eq 200 ]; then
				echo -e ${GREEN}" $bootstrap_source is alive. Success"${NC}
				response=1
			else
				echo -e ${RED}"No response from: $response_bootstrap_source reason: $response_bootstrap_source "${NC}
				response=0
			fi
		fi
		echo -e ${CYAN}"Checking connection to: $bootstrap_source_sig"${NC}
		response_bootstrap_source_sig=$(curl -s -o /dev/null -w "%{http_code}" -I $bootstrap_source_sig)
		if [ $? -ne 0 ]; then
			echo echo -e ${RED}"No response from: $bootstrap_source_sig reason $response_bootstrap_source_sig ."${NC}
				response2=0
		else
			if [ "$response_bootstrap_source_sig" -eq 200 ]; then
				echo -e ${GREEN}" $bootstrap_source_sig is alive. Success"${NC}
				response2=1
			else
				echo -e ${RED}"No response from: $bootstrap_source_sig reason: $response_bootstrap_source_sig "${NC}
				response2=0
			fi
		fi
	done
}

if [ $response -eq 0 ] || [ $response2 -eq 0 ]; then
	other_source_when_error	
fi

function download_and_check_sig(){
echo -e ${CYAN}"Downloading with curl $bootstrap_source"${NC}
sleep 1
curl -O  --output-dir "$script_dir/resources/Files/" $bootstrap_source
echo -e ${CYAN}"Downloading with curl $bootstrap_source_sig"${NC}
sleep 1
curl -O  --output-dir "$script_dir/resources/Files/" $bootstrap_source_sig

echo -e ${CYAN}"Importing keys rings for pierre@archlinux.org."${NC}
sleep 1
gpg --auto-key-locate clear,wkd -v --locate-external-key pierre@archlinux.org
echo -e ${CYAN}"Checking signatures of archlinux-bootstrap-x86_64.tar.zst with archlinux-bootstrap-x86_64.tar.zst.sig"${NC}
sleep 1
gpg --keyserver-options auto-key-retrieve --verify "$script_dir/resources/Files/archlinux-bootstrap-x86_64.tar.zst.sig" "$script_dir/resources/Files/archlinux-bootstrap-x86_64.tar.zst"
}

download_and_check_sig
if [ $? -eq 0 ]; then
	echo -e ${GREEN}"archlinux-bootstrap-x86_64.tar.zst is correctly signet."${NC}
		signature_error=0
		sleep 5
else
	echo -e ${RED}"Problem with archlinux-bootstrap-x86_64.tar.zst after checking the signatures."${NC}
	signature_error=1
	while [[ $signature_error -eq 1 ]];
	do	
		other_source_when_error
		download_and_check_sig
		if [ $? -eq 0 ]; then
			echo -e ${GREEN}"archlinux-bootstrap-x86_64.tar.zst is correctly signet."${NC}
			signature_error=0
			sleep 5
		else
			echo -e ${RED}"Problem with archlinux-bootstrap-x86_64.tar.zst after checking the signatures."${NC}
			signature_error=1
			sleep 5
		fi
	done
fi
















