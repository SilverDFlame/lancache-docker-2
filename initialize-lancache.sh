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
echo "## Checking if CURL is installed; If not, installing it"
echo "##"
echo "## -------------------------"
echo

if [ ! -f "/usr/bin/curl" ]; then
	apt-get install curl -y >/dev/null
fi

echo "## -------------------------"
echo "##"
echo "## Checking if DOCKER is installed; If not, installing it"
echo "##"
echo "## -------------------------"
echo

if [ ! -f "/usr/bin/docker" ]; then
    curl -sSL https://get.docker.com | bash
    usermod -aG docker "$USER"
fi

echo "## -------------------------"
echo "##"
echo "## Grabbing latest docker-compose"
echo "##"
echo "## -------------------------"
echo

COMPOSE_VER=$(curl -s -o /dev/null -I -w "%{redirect_url}\n" https://github.com/docker/compose/releases/latest | grep -oP "[0-9]+(\.[0-9]+)+$")
curl -o /usr/local/bin/docker-compose -L http://github.com/docker/compose/releases/download/$COMPOSE_VER/docker-compose-$(uname -s)-$(uname -m)
chmod +x /usr/local/bin/docker-compose
curl -L https://raw.githubusercontent.com/docker/compose/master/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose

echo "## -------------------------"
echo "##"
echo "## Creating Temporary Folders"
echo "##"
echo "## -------------------------"
echo

mkdir -p $lc_base_folder/config/
mkdir -p $lc_base_folder/temp
mkdir -p $lc_base_folder/temp/unbound/

echo "## -------------------------"
echo "##"
echo "## Setting Helper Functions"
echo "##"
echo "## -------------------------"
echo

get_ip() {
    ## Save the Mac Addresses if not already done
    lc_list_int=$( ls /sys/class/net | grep -v lo)
    echo "The usable interfaces for the Lancache are:"
    echo
    echo "$lc_list_int"
    echo

    ## Check if the Interface to be used is defined
    ## If not, ask to define it
    if [ ! "$lc_input_interface" ]; then
        ## Redundant check for the interface variable, just in case the above check gives false positive.
        ## If the variable is found, remove it
        if [ "$lc_input_interface" ]; then
            unset $lc_input_interface
        fi

        echo "(Please enter the interface to use)"
        echo The interfaces on this machine are:
        echo "$lc_list_int"
        read -r -p "Selected Interface: " lc_input
        echo You have entered: "$lc_input"
        export lc_input_interface=$lc_input
        echo
        echo Checking if this interface exists...
        echo

        ## Built in Check
        interface_check=$( ls /sys/class/net | grep "$lc_input_interface" >/dev/null )
        if $interface_check; then
            echo [ "$lc_date" ] !!! SUCCESS !!!
            echo It seems that "$lc_input_interface" exists
            echo The user "$USER" chose the interface: "$lc_input_interface" from the following:
            echo "$lc_list_int"
            echo
        else
            echo [ "$lc_date" ] !!! ERROR !!!
            echo Sorry you have entered an incorrect interface...
            echo
            echo The user: "$USER" entered the following interface: "$lc_input_interface",
            echo Wich doesnt exist
            echo
            echo These are the available interfaces "$USER" could choose from: "$lc_list_int"
            echo Please re-run this script.
            echo
            break
        fi
    fi

    lc_temp_ip=$(ip addr show dev "$lc_input_interface" | grep 'inet ' | grep -o '[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*' | head -n 1)
    echo Found the following IP address configured: "$lc_temp_ip"
    read -r -p "Do you want to use this IP? " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
    then
        export HOST_IP=$lc_temp_ip
    else
        confirm_ip
    fi
}

confirm_ip() {
    ip_confirmed="false"
    until [ $ip_confirmed = "true" ]; do
    echo
    read -r -p "What should the new IP be? " new_ip
    echo The IP will be set to: "$new_ip"
    read -r -p "Does this IP look correct? " ip_confirmation
    if [[ $ip_confirmation =~ ^([yY][eE][sS]|[yY])$ ]]
    then
        ip_confirmed="true"
        export HOST_IP=$new_ip
    else
        ip_confirmed="false"
    fi
    done
}

echo "## -------------------------"
echo "##"
echo "## Update Lancache config from github"
echo "##"
echo "## -------------------------"
echo

git submodule init
git submodule update --remote --recursive

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
sed -i "s|lc-host-vint|$lc_input_interface|g" $lc_base_folder/temp/interfaces
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
sed -i "s|8.8.8.8|1.1.1.1|g" $lc_base_folder/temp/unbound/unbound.conf
sed -i "s|8.8.4.4|1.0.0.1|g" $lc_base_folder/temp/unbound/unbound.conf

echo "## -------------------------"
echo "##"
echo "## Moving Base Files to The Correct Locations"
echo "##"
echo "## -------------------------"
echo

if [ -f "$lc_base_folder/temp/hosts" ]; then
	mv /etc/hosts /etc/hosts.bak
	cp $lc_base_folder/temp/hosts /etc/hosts
	else
	echo Could not find "$lc_base_folder/temp/hosts". Exiting.
	exit 1
fi

if [ -f "$lc_base_folder/temp/interfaces" ]; then
	mv /etc/netork/interfaces /etc/netork/interfaces.bak
	mv $lc_base_folder/temp/interfaces /etc/network/interfaces
	else
	echo Could not find "$lc_base_folder/temp/interfaces". Exiting.
	exit 1
fi


if [ -f "$lc_base_folder/temp/unbound/unbound.conf" ]; then
    mv ./lancache/unbound/unbound.conf ./lancache/unbound/unbound.conf.bak
	yes | cp $lc_base_folder/temp/unbound/unbound.conf ./lancache/unbound/unbound.conf
	else
	echo Could not find "$lc_base_folder/temp/unbound/unbound.conf". Exiting.
	exit 1
fi

## Change Limits of the system for Lancache to work without issues
if [ -f "./lancache/limits.conf" ]; then
	mv /etc/security/limits.conf /etc/security/limits.conf.bak
	cp ./lancache/limits.conf /etc/security/limits.conf
fi

# Updating local DNS resolvers to CloudFlare
echo "nameserver 1.1.1.1" >> /etc/resolv.conf
echo "nameserver 1.0.0.1" >> /etc/resolv.confc

echo "## -------------------------"
echo "##"
echo "## Installing traffic monitoring tools"
echo "##"
echo "## -------------------------"
echo
apt-get install nload iftop tcpdump tshark -y
echo "alias nloadMon='nload -U G -u M -i 102400 -o 102400'" >> ~/.bash_aliases
echo "alias iftopMon='iftop -i $lc_input_interface'" >> ~/.bash_aliases
source ~/.bash_aliases

## Clean up temp folder
rm -rf $lc_base_folder/temp

## Start Docker Containers
docker-compose up -d --build

echo "## -------------------------"
echo "##"
echo "## Reboot system for network changes to apply"
echo "##"
echo "## -------------------------"

#reboot
