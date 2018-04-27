#!/usr/bin/env bash
sudo echo "## -------------------------"
sudo echo "##"
sudo echo "## Setting Variables"
sudo echo "##"
sudo echo "## -------------------------"
sudo echo

lc_base_folder=./data/
lc_hn=$( hostname )
lc_eth_netmask=255.255.255.0
lc_date=$( date +"%m-%d-%y %T" )

sudo echo "## -------------------------"
sudo echo "##"
sudo echo "## Checking if NPLAN is installed; If it is, uninstall it and install IFUPDOWN"
sudo echo "## NPLAN is ubuntu's new network manager as of 17.10. It does not support virtual addressing."
sudo echo "## example: eth0:0 is not supported, and there's no current plan to support it in NPLAN"
sudo echo "##"
sudo echo "## Please provide Sudo privileges"
sudo echo "##"
sudo echo "## -------------------------"
sudo echo

if [[ $(apt list --installed | grep nplan) ]]; then
    sudo apt-get install ifupdown -y > /dev/null
    rm -rf /etc/netplan
    sudo apt-get purge nplan -y >/dev/null
fi

sudo echo "## -------------------------"
sudo echo "##"
sudo echo "## Checking if CURL is installed; If not, installing it"
sudo echo "##"
sudo echo "## -------------------------"
sudo echo

if [ ! -f "/usr/bin/curl" ]; then
	sudo apt-get install curl -y >/dev/null
fi

sudo echo "## -------------------------"
sudo echo "##"
sudo echo "## Checking if DOCKER is installed; If not, installing it"
sudo echo "##"
sudo echo "## -------------------------"
sudo echo

if [ ! -f "/usr/bin/docker" ]; then
    sudo curl -sSL https://get.docker.com | sudo bash
    sudo usermod -aG docker "$USER"
fi

sudo echo "## -------------------------"
sudo echo "##"
sudo echo "## Grabbing latest docker-compose"
sudo echo "##"
sudo echo "## -------------------------"
sudo echo

COMPOSE_VER=$(curl -s -o /dev/null -I -w "%{redirect_url}\n" https://github.com/docker/compose/releases/latest | grep -oP "[0-9]+(\.[0-9]+)+$")
sudo curl -o /usr/local/bin/docker-compose -L http://github.com/docker/compose/releases/download/$COMPOSE_VER/docker-compose-$(uname -s)-$(uname -m)
sudo chmod +x /usr/local/bin/docker-compose
sudo curl -L https://raw.githubusercontent.com/docker/compose/master/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose

sudo echo "## -------------------------"
sudo echo "##"
sudo echo "## Creating Temporary Folders"
sudo echo "##"
sudo echo "## -------------------------"
sudo echo

mkdir -p $lc_base_folder/config/
mkdir -p $lc_base_folder/temp
mkdir -p $lc_base_folder/temp/unbound/

sudo echo "## -------------------------"
sudo echo "##"
sudo echo "## Setting Helper Functions"
sudo echo "##"
sudo echo "## -------------------------"
sudo echo

get_ip() {
    ## Save the Mac Addresses if not already done
    lc_list_int=$( ls /sys/class/net | grep -v lo)
    sudo echo "The usable interfaces for the Lancache are:"
    sudo echo
    sudo echo "$lc_list_int"
    sudo echo

    ## Check if the Interface to be used is defined
    ## If not, ask to define it
    if [ ! "$lc_input_interface" ]; then
        ## Redundant check for the interface variable, just in case the above check gives false positive.
        ## If the variable is found, remove it
        if [ "$lc_input_interface" ]; then
            unset $lc_input_interface
        fi

        sudo echo "(Please enter the interface to use)"
        sudo echo The interfaces on this machine are:
        sudo echo "$lc_list_int"
        read -r -p "Selected Interface: " lc_input
        sudo echo You have entered: "$lc_input"
        export lc_input_interface=$lc_input
        sudo echo
        sudo echo Checking if this interface exists...
        sudo echo

        ## Built in Check
        interface_check=$( ls /sys/class/net | grep "$lc_input_interface" >/dev/null )
        if $interface_check; then
            sudo echo [ "$lc_date" ] !!! SUCCESS !!!
            sudo echo It seems that "$lc_input_interface" exists
            sudo echo The user "$USER" chose the interface: "$lc_input_interface" from the following:
            sudo echo "$lc_list_int"
            sudo echo
        else
            sudo echo [ "$lc_date" ] !!! ERROR !!!
            sudo echo Sorry you have entered an incorrect interface...
            sudo echo
            sudo echo The user: "$USER" entered the following interface: "$lc_input_interface",
            sudo echo Wich doesnt exist
            sudo echo
            sudo echo These are the available interfaces "$USER" could choose from: "$lc_list_int"
            sudo echo Please re-run this script.
            sudo echo
            break
        fi
    fi

    lc_temp_ip=$(ip addr show dev "$lc_input_interface" | grep 'inet ' | grep -o '[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*' | head -n 1)
    sudo echo Found the following IP address configured: "$lc_temp_ip"
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
    sudo echo
    read -r -p "What should the new IP be? " new_ip
    sudo echo The IP will be set to: "$new_ip"
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

sudo echo "## -------------------------"
sudo echo "##"
sudo echo "## Update Lancache config from github"
sudo echo "##"
sudo echo "## -------------------------"
sudo echo

git submodule init
git submodule update --remote --recursive

sudo echo "## -------------------------"
sudo echo "##"
sudo echo "## Starting initialize script"
sudo echo "## Detecting IP"
sudo echo "##"
sudo echo "## -------------------------"
sudo echo

if [[ -z $HOST_IP ]]; then
  get_ip

  if [[ -n $HOST_IP ]]; then
    sudo echo Detected configured host IP as "$HOST_IP"
    sudo echo Creating Interface IPs from "$HOST_IP"
    HOST_IP_P1=$(sudo echo "${HOST_IP}" | tr "." " " | awk '{ print $1 }')
    HOST_IP_P2=$(sudo echo "${HOST_IP}" | tr "." " " | awk '{ print $2 }')
    HOST_IP_P3=$(sudo echo "${HOST_IP}" | tr "." " " | awk '{ print $3 }')
    HOST_IP_P4=$(sudo echo "${HOST_IP}" | tr "." " " | awk '{ print $4 }')
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

    sudo echo Interface IPs created. Starting IP Assignments
    sudo echo
  else
    sudo echo Could not determine set host IP. Exiting.
    exit 1
  fi
fi

sudo echo "## -------------------------"
sudo echo "##"
sudo echo "## update proxy-bind in vhosts-enabled file"
sudo echo "##"
sudo echo "## -------------------------"
sudo echo
## Change the Proxy Bind in Lancache Configs
sudo sed -i 's|lc-host-proxybind|'$lc_ip'|g' ./lancache/conf/vhosts-enabled/*.conf

sudo echo "## -------------------------"
sudo echo "##"
sudo echo "## Make the Necessary Changes For The New Host File"
sudo echo "##"
sudo echo "## -------------------------"
sudo echo

sudo cp ./lancache/hosts $lc_base_folder/temp/hosts
sudo sed -i "s|lc-host-apple|$lc_ip_apple|g" $lc_base_folder/temp/hosts
sudo sed -i "s|lc-host-arena|$lc_ip_arena|g" $lc_base_folder/temp/hosts
sudo sed -i "s|lc-host-blizzard|$lc_ip_blizzard|" $lc_base_folder/temp/hosts
sudo sed -i "s|lc-host-digitalextremes|$lc_ip_digitalextremes|g" $lc_base_folder/temp/hosts
sudo sed -i "s|lc-host-enmasse|$lc_ip_enmasse|g" $lc_base_folder/temp/hosts
sudo sed -i "s|lc-host-glyph|$lc_ip_glyph|" $lc_base_folder/temp/hosts
sudo sed -i "s|lc-host-gog|$lc_ip_gog|g" $lc_base_folder/temp/hosts
sudo sed -i "s|lc-host-hirez|$lc_ip_hirez|g" $lc_base_folder/temp/hosts
sudo sed -i "s|lc-host-microsoft|$lc_ip_microsoft|g" $lc_base_folder/temp/hosts
sudo sed -i "s|lc-host-origin|$lc_ip_origin|g" $lc_base_folder/temp/hosts
sudo sed -i "s|lc-host-pearlabyss|$lc_ip_pearlabyss|g" $lc_base_folder/temp/hosts
sudo sed -i "s|lc-host-proxybind|$HOST_IP|g" $lc_base_folder/temp/hosts
sudo sed -i "s|lc-host-riot|$lc_ip_riot|g" $lc_base_folder/temp/hosts
sudo sed -i "s|lc-host-sony|$lc_ip_sony|g" $lc_base_folder/temp/hosts
sudo sed -i "s|lc-host-steam|$lc_ip_steam|g" $lc_base_folder/temp/hosts
sudo sed -i "s|lc-host-uplay|$lc_ip_uplay|g" $lc_base_folder/temp/hosts
sudo sed -i "s|lc-host-wargaming|$lc_ip_wargaming|g" $lc_base_folder/temp/hosts
sudo sed -i "s|lc-host-zenimax|$lc_ip_zenimax|g" $lc_base_folder/temp/hosts
sudo sed -i "s|lc-hostname|$lc_hn|g" $lc_base_folder/temp/hosts

sudo echo "## -------------------------"
sudo echo "##"
sudo echo "## Make the Necessary Changes For The New Interfaces File"
sudo echo "##"
sudo echo "## -------------------------"
sudo echo

sudo cp ./lancache/interfaces $lc_base_folder/temp/interfaces
sudo sed -i "s|lc-host-apple|$lc_ip_apple|g" $lc_base_folder/temp/interfaces
sudo sed -i "s|lc-host-arena|$lc_ip_arena|g" $lc_base_folder/temp/interfaces
sudo sed -i "s|lc-host-blizzard|$lc_ip_blizzard|g" $lc_base_folder/temp/interfaces
sudo sed -i "s|lc-host-digitalextremes|$lc_ip_digitalextremes|g" $lc_base_folder/temp/interfaces
sudo sed -i "s|lc-host-enmasse|$lc_ip_enmasse|g" $lc_base_folder/temp/interfaces
sudo sed -i "s|lc-host-glyph|$lc_ip_glyph|g" $lc_base_folder/temp/interfaces
sudo sed -i "s|lc-host-gog|$lc_ip_gog|g" $lc_base_folder/temp/interfaces
sudo sed -i "s|lc-host-hirez|$lc_ip_hirez|g" $lc_base_folder/temp/interfaces
sudo sed -i "s|lc-host-ip|$HOST_IP|g" $lc_base_folder/temp/interfaces
sudo sed -i "s|lc-host-microsoft|$lc_ip_microsoft|g" $lc_base_folder/temp/interfaces
sudo sed -i "s|lc-host-netmask|$lc_eth_netmask|g" $lc_base_folder/temp/interfaces
sudo sed -i "s|lc-host-origin|$lc_ip_origin|g" $lc_base_folder/temp/interfaces
sudo sed -i "s|lc-host-pearlabyss|$lc_ip_pearlabyss|g" $lc_base_folder/temp/interfaces
sudo sed -i "s|lc-host-riot|$lc_ip_riot|g" $lc_base_folder/temp/interfaces
sudo sed -i "s|lc-host-sony|$lc_ip_sony|g" $lc_base_folder/temp/interfaces
sudo sed -i "s|lc-host-steam|$lc_ip_steam|g" $lc_base_folder/temp/interfaces
sudo sed -i "s|lc-host-uplay|$lc_ip_uplay|g" $lc_base_folder/temp/interfaces
sudo sed -i "s|lc-host-vint|$lc_input_interface|g" $lc_base_folder/temp/interfaces
sudo sed -i "s|lc-host-wargaming|$lc_ip_wargaming|g" $lc_base_folder/temp/interfaces
sudo sed -i "s|lc-host-zenimax|$lc_ip_zenimax|g" $lc_base_folder/temp/interfaces

sudo echo "## -------------------------"
sudo echo "##"
sudo echo "## Preparing configuration for unbound"
sudo echo "##"
sudo echo "## -------------------------"
sudo echo

sudo cp ./lancache/unbound/unbound.conf $lc_base_folder/temp/unbound/
sudo sed -i "s|lc-host-apple|$lc_ip_apple|g" $lc_base_folder/temp/unbound/unbound.conf
sudo sed -i "s|lc-host-arena|$lc_ip_arena|g" $lc_base_folder/temp/unbound/unbound.conf
sudo sed -i "s|lc-host-blizzard|$lc_ip_blizzard|g" $lc_base_folder/temp/unbound/unbound.conf
sudo sed -i "s|lc-host-digitalextremes|$lc_ip_digitalextremes|g" $lc_base_folder/temp/unbound/unbound.conf
sudo sed -i "s|lc-host-enmasse|$lc_ip_enmasse|g" $lc_base_folder/temp/unbound/unbound.conf
sudo sed -i "s|lc-host-glyph|$lc_ip_glyph|g" $lc_base_folder/temp/unbound/unbound.conf
sudo sed -i "s|lc-host-gog|$lc_ip_gog|g" $lc_base_folder/temp/unbound/unbound.conf
sudo sed -i "s|lc-host-hirez|$lc_ip_hirez|g" $lc_base_folder/temp/unbound/unbound.conf
sudo sed -i "s|lc-host-ip|$HOST_IP|g" $lc_base_folder/temp/unbound/unbound.conf
sudo sed -i "s|lc-host-microsoft|$lc_ip_microsoft|g" $lc_base_folder/temp/unbound/unbound.conf
sudo sed -i "s|lc-host-origin|$lc_ip_origin|g" $lc_base_folder/temp/unbound/unbound.conf
sudo sed -i "s|lc-host-pearlabyss|$lc_ip_pearlabyss|g" $lc_base_folder/temp/unbound/unbound.conf
sudo sed -i "s|lc-host-proxybind|$HOST_IP|g" $lc_base_folder/temp/unbound/unbound.conf
sudo sed -i "s|lc-host-riot|$lc_ip_riot|g" $lc_base_folder/temp/unbound/unbound.conf
sudo sed -i "s|lc-host-sony|$lc_ip_sony|g" $lc_base_folder/temp/unbound/unbound.conf
sudo sed -i "s|lc-host-steam|$lc_ip_steam|g" $lc_base_folder/temp/unbound/unbound.conf
sudo sed -i "s|lc-host-uplay|$lc_ip_uplay|g" $lc_base_folder/temp/unbound/unbound.conf
sudo sed -i "s|lc-host-wargaming|$lc_ip_wargaming|g" $lc_base_folder/temp/unbound/unbound.conf
sudo sed -i "s|lc-host-zenimax|$lc_ip_zenimax|g" $lc_base_folder/temp/unbound/unbound.conf
sudo sed -i "s|8.8.8.8|1.1.1.1|g" $lc_base_folder/temp/unbound/unbound.conf
sudo sed -i "s|8.8.4.4|1.0.0.1|g" $lc_base_folder/temp/unbound/unbound.conf

sudo echo "## -------------------------"
sudo echo "##"
sudo echo "## Moving Base Files to The Correct Locations"
sudo echo "##"
sudo echo "## -------------------------"
sudo echo

if [ -f "$lc_base_folder/temp/hosts" ]; then
	sudo mv /etc/hosts /etc/hosts.bak
	sudo cp $lc_base_folder/temp/hosts /etc/hosts
	else
	sudo echo Could not find "$lc_base_folder/temp/hosts". Exiting.
	exit 1
fi

if [ -f "$lc_base_folder/temp/interfaces" ]; then
	sudo mv /etc/netork/interfaces /etc/netork/interfaces.bak
	sudo mv $lc_base_folder/temp/interfaces /etc/network/interfaces
	else
	sudo echo Could not find "$lc_base_folder/temp/interfaces". Exiting.
	exit 1
fi


if [ -f "$lc_base_folder/temp/unbound/unbound.conf" ]; then
    sudo mv ./lancache/unbound/unbound.conf ./lancache/unbound/unbound.conf.bak
	yes | cp $lc_base_folder/temp/unbound/unbound.conf ./lancache/unbound/unbound.conf
	else
	sudo echo Could not find "$lc_base_folder/temp/unbound/unbound.conf". Exiting.
	exit 1
fi

## Change Limits of the system for Lancache to work without issues
if [ -f "./lancache/limits.conf" ]; then
	sudo mv /etc/security/limits.conf /etc/security/limits.conf.bak
	sudo cp ./lancache/limits.conf /etc/security/limits.conf
fi

# Updating local DNS resolvers to CloudFlare
sudo echo "nameserver 1.1.1.1" >> /etc/resolv.conf
sudo echo "nameserver 1.0.0.1" >> /etc/resolv.confc

sudo echo "## -------------------------"
sudo echo "##"
sudo echo "## Installing traffic monitoring tools"
sudo echo "##"
sudo echo "## -------------------------"
sudo echo
sudo apt-get install nload iftop tcpdump tshark -y
sudo echo "alias nloadMon='nload -U G -u M -i 102400 -o 102400'" >> ~/.bash_aliases
sudo echo "alias iftopMon='iftop -i $lc_input_interface'" >> ~/.bash_aliases
source ~/.bash_aliases

## Clean up temp folder
sudo rm -rf $lc_base_folder/temp

## Start Docker Containers
docker-compose up -d --build

sudo echo "## -------------------------"
sudo echo "##"
sudo echo "## Reboot system for network changes to apply"
sudo echo "##"
sudo echo "## -------------------------"

#reboot
