#!/usr/bin/env bash
echo "## -------------------------"
echo "##"
echo "## Setting Variables"
echo "##"
echo "## -------------------------"
echo

lc_base_folder=./data/
lc_hn=$( hostname )
lc_eth_netmask=255.255.255.0
lc_date=$( date +"%m-%d-%y %T" )

echo "## -------------------------"
echo "##"
echo "## Checking if NPLAN is installed; If it is, uninstall it and install IFUPDOWN"
echo "## NPLAN is ubuntu's new network manager as of 17.10. It does not support virtual addressing."
echo "## example: eth0:0 is not supported, and there's no current plan to support it in NPLAN"
echo "##"
echo "## -------------------------"
echo

if [apt list --installed | grep nplan]; then
    sudo apt-get install ifupdown
    sudo apt-get purge nplan
fi

echo "## -------------------------"
echo "##"
echo "## Checking if CURL is installed; If not, installing it"
echo "##"
echo "## -------------------------"
echo

if [ ! -f "/usr/bin/curl" ]; then
	sudo apt-get install curl -y >/dev/null
fi

echo "## -------------------------"
echo "##"
echo "## Checking if DOCKER is installed; If not, installing it"
echo "##"
echo "## -------------------------"
echo

if [ ! -f "/usr/bin/docker" ]; then
    curl -sSL https://get.docker.com | sudo bash
    sudo usermod -aG docker "$USER"
fi

echo "## -------------------------"
echo "##"
echo "## Grabbing latest docker-compose"
echo "##"
echo "## -------------------------"
echo

latest_compose_url=$(curl -s -L https://github.com/docker/compose/releases/latest | grep -E -o "/docker/compose/releases/download/[0-9\.]*/docker-compose-$(uname -s)-$(uname -m)")
sudo curl -o /usr/local/bin/docker-compose -L "http://www.github.com$latest_compose_url"
sudo chmod +x /usr/local/bin/docker-compose

echo "## -------------------------"
echo "##"
echo "## Creating Temporary Folders"
echo "##"
echo "## -------------------------"
echo

sudo mkdir -p $lc_base_folder/config/
sudo mkdir -p $lc_base_folder/temp
sudo mkdir -p $lc_base_folder/temp/unbound/

echo "## -------------------------"
echo "##"
echo "## Setting Helper Functions"
echo "##"
echo "## -------------------------"
echo

get_ip() {
    ## Save the Mac Addresses if not already done
    lc_list_int=$( ls /sys/class/net | grep -v lo)
    lc_list_mac=$( cat /sys/class/net/*/address | grep -v 00:00:00:00:00:00 )
    echo The MAC Adresses for all interfaces are:
    echo "$lc_list_int"
    echo "$lc_list_mac"
    echo

    ## Check if the Interface is defined
    ## If not will ask for the question
    if [ ! -f "$lc_base_folder/config/interface_used" ]; then
        if [ -f "$lc_base_folder/config/interface_used" ]; then
            rm -rf $lc_base_folder/config/interface_used
        fi

        echo Please enter the interface to use:
        echo The interfaces on this machine are: "$lc_list_int"
            read -r lc_input
        echo You have entered: "$lc_input"
        lc_input_interface=$lc_input
        echo
        echo Checking if this interface exists...
        echo

        ## Built in Check
        interface_check=$( ls /sys/class/net | grep "$lc_input_interface" >/dev/null )
        if $interface_check; then
            echo [ "$lc_date" ] !!! ERROR !!!
            echo Sorry you have entered a wrong interface...
            echo
            echo The user: "$USER" entered the following interface: "$lc_input_interface"
            echo Wich doesnt exist
            echo
            echo These are the available interfaces "$USER" could choose from: "$lc_list_int"
            echo

        else
            echo It seems that "$lc_input_interface" exists
            echo
            echo Now defining the necessary files
            echo "$lc_input_interface" >$lc_base_folder/config/interface_used
            echo [ lc_date ] !!! SUCCESS !!!
            echo The user "$USER" chose the following interface: "$lc_input_interface" from "$lc_list_int"
            echo
        fi
    fi

    lc_temp_ip=$(ip addr show dev "$( cat $lc_base_folder/config/interface_used )" | grep 'inet ' | grep -o '[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*' | head -n 1)
    echo Found the following IP address configured: "$lc_temp_ip"
    read -p "Do you want to use this IP?" -n 1 -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
    then
        export HOST_IP=$lc_temp_ip
    else
        confirm_ip
    fi
}

confirm_ip() {
    while false; do
    echo What should the new IP be?
    read -r new_ip
    echo The IP will be set to: "$new_ip"
    read -r -p "Does this IP look correct?" ip_confirmation
    if [[ $ip_confirmation =~ ^([yY][eE][sS]|[yY])$ ]]
    then
        export HOST_IP=$new_ip
        return
    else
        false
    fi
    done
}

echo "## -------------------------"
echo "##"
echo "## Starting initialize script"
echo "## Detecting IP"
echo "##"
echo "## -------------------------"
echo

if [[ -z $HOST_IP ]]; then
  get_ip

  if [[ -n $HOST_IP ]]; then
    echo Detected configured host IP as "$HOST_IP"
    echo Creating Interface IPs from "$HOST_IP"
    HOST_IP_P1=$(echo "${HOST_IP}" | tr "." " " | awk '{ print $1 }')
    HOST_IP_P2=$(echo "${HOST_IP}" | tr "." " " | awk '{ print $2 }')
    HOST_IP_P3=$(echo "${HOST_IP}" | tr "." " " | awk '{ print $3 }')
    HOST_IP_P4=$(echo "${HOST_IP}" | tr "." " " | awk '{ print $4 }')
    ## Increment the last IP digit for every Game
    lc_incr_steam=$((HOST_IP_P4+1))
    export lc_ip_steam=$HOST_IP_P1.$HOST_IP_P2.$HOST_IP_P3.$lc_incr_steam

    lc_incr_riot=$((HOST_IP_P4+2))
    export lc_ip_riot=$HOST_IP_P1.$HOST_IP_P2.$HOST_IP_P3.$lc_incr_riot

    lc_incr_blizzard=$((HOST_IP_P4+3))
    export lc_ip_blizzard=$HOST_IP_P1.$HOST_IP_P2.$HOST_IP_P3.$lc_incr_blizzard

    lc_incr_hirez=$((HOST_IP_P4+4))
    export lc_ip_hirez=$HOST_IP_P1.$HOST_IP_P2.$HOST_IP_P3.$lc_incr_hirez

    lc_incr_origin=$((HOST_IP_P4+5))
    export lc_ip_origin=$HOST_IP_P1.$HOST_IP_P2.$HOST_IP_P3.$lc_incr_origin

    lc_incr_sony=$((HOST_IP_P4+6))
    export lc_ip_sony=$HOST_IP_P1.$HOST_IP_P2.$HOST_IP_P3.$lc_incr_sony

    lc_incr_microsoft=$((HOST_IP_P4+7))
    export lc_ip_microsoft=$HOST_IP_P1.$HOST_IP_P2.$HOST_IP_P3.$lc_incr_microsoft

    lc_incr_enmasse=$((HOST_IP_P4+8))
    export lc_ip_enmasse=$HOST_IP_P1.$HOST_IP_P2.$HOST_IP_P3.$lc_incr_enmasse

    lc_incr_gog=$((HOST_IP_P4+9))
    export lc_ip_gog=$HOST_IP_P1.$HOST_IP_P2.$HOST_IP_P3.$lc_incr_gog

    lc_incr_arena=$((HOST_IP_P4+10))
    export lc_ip_arena=$HOST_IP_P1.$HOST_IP_P2.$HOST_IP_P3.$lc_incr_arena

    lc_incr_wargaming=$((HOST_IP_P4+11))
    export lc_ip_wargaming=$HOST_IP_P1.$HOST_IP_P2.$HOST_IP_P3.$lc_incr_wargaming

    lc_incr_uplay=$((HOST_IP_P4+12))
    export lc_ip_uplay=$HOST_IP_P1.$HOST_IP_P2.$HOST_IP_P3.$lc_incr_uplay

    lc_incr_apple=$((HOST_IP_P4+13))
    export lc_ip_apple=$HOST_IP_P1.$HOST_IP_P2.$HOST_IP_P3.$lc_incr_apple

    lc_incr_glyph=$((HOST_IP_P4+14))
    export lc_ip_glyph=$HOST_IP_P1.$HOST_IP_P2.$HOST_IP_P3.$lc_incr_glyph

    lc_incr_zenimax=$((HOST_IP_P4+15))
    export lc_ip_zenimax=$HOST_IP_P1.$HOST_IP_P2.$HOST_IP_P3.$lc_incr_zenimax

    lc_incr_digitalextremes=$((HOST_IP_P4+16))
    export lc_ip_digitalextremes=$HOST_IP_P1.$HOST_IP_P2.$HOST_IP_P3.$lc_incr_digitalextremes

    lc_incr_pearlabyss=$((HOST_IP_P4+17))
    export lc_ip_pearlabyss=$HOST_IP_P1.$HOST_IP_P2.$HOST_IP_P3.$lc_incr_pearlabyss

    echo Interface IPs created. Starting IP Assignments
    echo
  else
    echo Could not determine set host IP. Exiting.
    exit 1
  fi
fi

echo "## -------------------------"
echo "##"
echo "## update proxy-bind in vhosts-enabled file"
echo "##"
echo "## -------------------------"
echo
## Change the Proxy Bind in Lancache Configs
sed -i 's|lc-host-proxybind|'$lc_ip'|g' ./lancache/conf/vhosts-enabled/*.conf

echo "## -------------------------"
echo "##"
echo "## Make the Necessary Changes For The New Host File"
echo "##"
echo "## -------------------------"
echo

cp ./lancache/hosts $lc_base_folder/temp/hosts
sed -i "s|lc-host-apple|$lc_ip_apple|g" $lc_base_folder/temp/hosts
sed -i "s|lc-host-arena|$lc_ip_arena|g" $lc_base_folder/temp/hosts
sed -i "s|lc-host-blizzard|$lc_ip_blizzard|" $lc_base_folder/temp/hosts
sed -i "s|lc-host-digitalextremes|$lc_ip_digitalextremes|g" $lc_base_folder/temp/hosts
sed -i "s|lc-host-enmasse|$lc_ip_enmasse|g" $lc_base_folder/temp/hosts
sed -i "s|lc-host-glyph|$lc_ip_glyph|" $lc_base_folder/temp/hosts
sed -i "s|lc-host-gog|$lc_ip_gog|g" $lc_base_folder/temp/hosts
sed -i "s|lc-host-hirez|$lc_ip_hirez|g" $lc_base_folder/temp/hosts
sed -i "s|lc-host-microsoft|$lc_ip_microsoft|g" $lc_base_folder/temp/hosts
sed -i "s|lc-host-origin|$lc_ip_origin|g" $lc_base_folder/temp/hosts
sed -i "s|lc-host-pearlabyss|$lc_ip_pearlabyss|g" $lc_base_folder/temp/hosts
sed -i "s|lc-host-proxybind|$HOST_IP|g" $lc_base_folder/temp/hosts
sed -i "s|lc-host-riot|$lc_ip_riot|g" $lc_base_folder/temp/hosts
sed -i "s|lc-host-sony|$lc_ip_sony|g" $lc_base_folder/temp/hosts
sed -i "s|lc-host-steam|$lc_ip_steam|g" $lc_base_folder/temp/hosts
sed -i "s|lc-host-uplay|$lc_ip_uplay|g" $lc_base_folder/temp/hosts
sed -i "s|lc-host-wargaming|$lc_ip_wargaming|g" $lc_base_folder/temp/hosts
sed -i "s|lc-host-zenimax|$lc_ip_zenimax|g" $lc_base_folder/temp/hosts
sed -i "s|lc-hostname|$lc_hn|g" $lc_base_folder/temp/hosts

echo "## -------------------------"
echo "##"
echo "## Make the Necessary Changes For The New Interfaces File"
echo "##"
echo "## -------------------------"
echo

cp ./lancache/interfaces $lc_base_folder/temp/interfaces
sed -i "s|lc-host-apple|$lc_ip_apple|g" $lc_base_folder/temp/interfaces
sed -i "s|lc-host-arena|$lc_ip_arena|g" $lc_base_folder/temp/interfaces
sed -i "s|lc-host-blizzard|$lc_ip_blizzard|g" $lc_base_folder/temp/interfaces
sed -i "s|lc-host-digitalextremes|$lc_ip_digitalextremes|g" $lc_base_folder/temp/interfaces
sed -i "s|lc-host-enmasse|$lc_ip_enmasse|g" $lc_base_folder/temp/interfaces
sed -i "s|lc-host-glyph|$lc_ip_glyph|g" $lc_base_folder/temp/interfaces
sed -i "s|lc-host-gog|$lc_ip_gog|g" $lc_base_folder/temp/interfaces
sed -i "s|lc-host-hirez|$lc_ip_hirez|g" $lc_base_folder/temp/interfaces
sed -i "s|lc-host-ip|$HOST_IP|g" $lc_base_folder/temp/interfaces
sed -i "s|lc-host-microsoft|$lc_ip_microsoft|g" $lc_base_folder/temp/interfaces
sed -i "s|lc-host-netmask|$lc_eth_netmask|g" $lc_base_folder/temp/interfaces
sed -i "s|lc-host-origin|$lc_ip_origin|g" $lc_base_folder/temp/interfaces
sed -i "s|lc-host-pearlabyss|$lc_ip_pearlabyss|g" $lc_base_folder/temp/interfaces
sed -i "s|lc-host-riot|$lc_ip_riot|g" $lc_base_folder/temp/interfaces
sed -i "s|lc-host-sony|$lc_ip_sony|g" $lc_base_folder/temp/interfaces
sed -i "s|lc-host-steam|$lc_ip_steam|g" $lc_base_folder/temp/interfaces
sed -i "s|lc-host-uplay|$lc_ip_uplay|g" $lc_base_folder/temp/interfaces
sed -i "s|lc-host-vint|$( cat $lc_base_folder/config/interface_used )|g" $lc_base_folder/temp/interfaces
sed -i "s|lc-host-wargaming|$lc_ip_wargaming|g" $lc_base_folder/temp/interfaces
sed -i "s|lc-host-zenimax|$lc_ip_zenimax|g" $lc_base_folder/temp/interfaces

echo "## -------------------------"
echo "##"
echo "## Preparing configuration for unbound"
echo "##"
echo "## -------------------------"
echo

cp ./lancache/unbound/unbound.conf $lc_base_folder/temp/unbound/
sed -i "s|lc-host-apple|$lc_ip_apple|g" $lc_base_folder/temp/unbound/unbound.conf
sed -i "s|lc-host-arena|$lc_ip_arena|g" $lc_base_folder/temp/unbound/unbound.conf
sed -i "s|lc-host-blizzard|$lc_ip_blizzard|g" $lc_base_folder/temp/unbound/unbound.conf
sed -i "s|lc-host-digitalextremes|$lc_ip_digitalextremes|g" $lc_base_folder/temp/unbound/unbound.conf
sed -i "s|lc-host-enmasse|$lc_ip_enmasse|g" $lc_base_folder/temp/unbound/unbound.conf
sed -i "s|lc-host-glyph|$lc_ip_glyph|g" $lc_base_folder/temp/unbound/unbound.conf
sed -i "s|lc-host-gog|$lc_ip_gog|g" $lc_base_folder/temp/unbound/unbound.conf
sed -i "s|lc-host-hirez|$lc_ip_hirez|g" $lc_base_folder/temp/unbound/unbound.conf
sed -i "s|lc-host-ip|$HOST_IP|g" $lc_base_folder/temp/unbound/unbound.conf
sed -i "s|lc-host-microsoft|$lc_ip_microsoft|g" $lc_base_folder/temp/unbound/unbound.conf
sed -i "s|lc-host-origin|$lc_ip_origin|g" $lc_base_folder/temp/unbound/unbound.conf
sed -i "s|lc-host-pearlabyss|$lc_ip_pearlabyss|g" $lc_base_folder/temp/unbound/unbound.conf
sed -i "s|lc-host-proxybind|$HOST_IP|g" $lc_base_folder/temp/unbound/unbound.conf
sed -i "s|lc-host-riot|$lc_ip_riot|g" $lc_base_folder/temp/unbound/unbound.conf
sed -i "s|lc-host-sony|$lc_ip_sony|g" $lc_base_folder/temp/unbound/unbound.conf
sed -i "s|lc-host-steam|$lc_ip_steam|g" $lc_base_folder/temp/unbound/unbound.conf
sed -i "s|lc-host-uplay|$lc_ip_uplay|g" $lc_base_folder/temp/unbound/unbound.conf
sed -i "s|lc-host-wargaming|$lc_ip_wargaming|g" $lc_base_folder/temp/unbound/unbound.conf
sed -i "s|lc-host-zenimax|$lc_ip_zenimax|g" $lc_base_folder/temp/unbound/unbound.conf

echo "## -------------------------"
echo "##"
echo "## Moving Base Files to The Correct Locations"
echo "##"
echo "## -------------------------"
echo

if [ -f "$lc_base_folder/temp/hosts" ]; then
	sudo mv /etc/hosts /etc/hosts.bak
	sudo cp $lc_base_folder/temp/hosts /etc/hosts
	else
	echo Could not find "$lc_base_folder/temp/hosts". Exiting.
	exit 1
fi

if [ -f "$lc_base_folder/temp/interfaces" ]; then
	sudo mv /etc/netork/interfaces /etc/netork/interfaces.bak
	sudo mv $lc_base_folder/temp/interfaces /etc/network/interfaces
	else
	echo Could not find "$lc_base_folder/temp/interfaces". Exiting.
	exit 1
fi


if [ -f "$lc_base_folder/temp/unbound" ]; then
    sudo mv ./lancache/unbound/unbound.conf ./lancache/unbound/unbound.conf.bak
	yes | cp $lc_base_folder/temp/unbound/unbound.conf ./lancache/unbound/unbound.conf
	else
	echo Could not find "$lc_base_folder/temp/unbound". Exiting.
	exit 1
fi

## Change Limits of the system for Lancache to work without issues
if [ -f "./lancache/limits.conf" ]; then
	sudo mv /etc/security/limits.conf /etc/security/limits.conf.bak
	sudo cp ./lancache/limits.conf /etc/security/limits.conf
fi

# Updating local DNS resolvers to Google
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf

# Install traffic monitoring tools
apt-get install nload iftop tcpdump tshark -y

## Clean up temp folder
rm -rf $lc_base_folder/temp

## Start Docker Containers
docker-compose up -d --build

echo "## -------------------------"
echo "##"
echo "## Reboot system for network changes to apply"
echo "##"
echo "## -------------------------"

sudo reboot
