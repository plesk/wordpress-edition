#!/usr/bin/env bash
# -------------------------------------------------------------------------
#  Ubuntu Plesk server - Installation script for Plesk on Ubuntu
# -------------------------------------------------------------------------
# Website:       https://virtubox.net
# GitHub:        https://github.com/VirtuBox/ubuntu-plesk-server
# Source : https://github.com/plesk/wordpress-edition
# Copyright (c) 2019 VirtuBox <contact@virtubox.net>
# This script is licensed under Apache 2.0
# -------------------------------------------------------------------------
# Version 1.0.0 - 2019-08-21
# -------------------------------------------------------------------------

# Edit variables for Plesk pre-configuration

plesk_email='admin@test.tst'
plesk_pass='PleskUbuntu123@@'
plesk_name='admin'

# Plesk UI View - can be set to Service Provider View (spv) or Power User View (puv)
plesk_ui=spv

# Turn on Fail2Ban, yes or no, Keep in mind you need to provide temp license for initialization for this to work
fail2ban=yes

# Turn on http2
http2=yes

# PCI COMPLIANCE
pci_compliance=false

# Turn on Cloning - Set to "on" if this it to make a Golden Image, set to "off" if for remote installation
clone=off

# Check if user is root

if [ "$(id -u)" != "0" ]; then
    echo "Error: You must be root to run this script, please use the root user to install the software."
    echo ""
    echo "Use 'su - root' to login as root"
    exit 1
fi

if {
    plesk version >/dev/null 2>&1
}; then
    readonly plesk_installed="y"
else
    plesk_installed=""
fi

readonly plesk_linux_distro=$(lsb_release -is)
readonly plesk_distro_version=$(lsb_release -sc)
readonly plesk_distro_id=$(lsb_release -rs)
readonly plesk_srv_arch="$(uname -m)"
readonly plesk_kvm_detec=$(systemd-detect-virt)

##################################
# Welcome
##################################

echo ""
echo "Welcome to ubuntu-plesk-server-setup script."
echo ""

while [ "$#" -gt 0 ]; do
    case "$1" in
    --interactive)
        interactive_install="y"
        ;;
    --travis)
        travis="y"
        release_tiers="testing"
        agreement="true"
        mariadb_server_install="y"
        mariadb_version_install="10.5"
        ;;
    -n | --name)
        plesk_name="$2"
        shift
        ;;
    -p | --password)
        plesk_pass="$2"
        shift
        ;;
    --email)
        plesk_email="$2"
        shift
        ;;
    --testing)
        release_tiers="testing"
        ;;
    -r | --release)
        release_tiers="$2"
        shift
        ;;
    -y | --agreement)
        agreement="true"
        ;;
    -i | --license)
        activation_key="$2"
        shift
        ;;
    -m | --mariadb)
        mariadb_server_install="y"
        mariadb_version_install="$2"
        shift
        ;;
    *) ;;
    esac
    shift
done

##################################
# Menu
##################################
echo "#####################################"
echo "             Warning                 "
echo "#####################################"
echo "This script will only allow ssh connection with ssh-keys"
echo "Make sure you have properly installed your public key in $HOME/.ssh/authorized_keys"
echo "#####################################"
sleep 1
if [ "$interactive_install" = "y" ]; then
    if [ ! -d /etc/mysql ]; then
        echo "#####################################"
        echo "MariaDB server"
        echo "#####################################"
        echo ""
        echo "Do you want to install MariaDB-server ? (y/n)"
        while [[ $mariadb_server_install != "y" && $mariadb_server_install != "n" ]]; do
            echo -e "Select an option [y/n]: "
            read -r mariadb_server_install
        done
        if [[ "$mariadb_server_install" == "y" ]]; then
            echo ""
            echo "What version of MariaDB Client/Server do you want to install, 10.2, 10.3 or 10.5 ?"
            while [[ $mariadb_version_install != "10.2" && $mariadb_version_install != "10.3" && $mariadb_version_install != "10.5" ]]; do
                echo -e "Select an option [10.2 / 10.3 / 10.5]: "
                read -r mariadb_version_install
            done
        fi
        sleep 1
    fi
    if [ -z "$agreement" ]; then
        echo -e "Do you agree with Plesk license terms ? (See : https://www.plesk.com/legal/)"
        while [[ $agreement != "y" && $agreement != "n" ]]; do
            echo -e "Select an option [y/n]: "
            read -r agreement
        done
    fi

fi
if [ -z "$plesk_installed" ]; then
    if [ -z "$mariadb_server_install" ]; then
        mariadb_server_install="y"
    fi
    if [ -z "$mariadb_version_install" ]; then
        mariadb_version_install="10.5"
    fi
fi

# Test to make sure all initialization values are set
if [[ -z "$plesk_email" || -z "$plesk_pass" || -z "$plesk_name" || -z "$agreement" ]]; then
    echo 'One or more variables are undefined. Please check your initialization values.'
    exit 1
fi

echo ""
echo "#####################################"
echo "Starting server setup in 5 seconds"
echo "use CTRL + C if you want to cancel installation"
echo "#####################################"
sleep 5

export DEBIAN_FRONTEND=noninteractive

##################################
# Update packages
##################################

echo "##########################################"
echo " Updating Packages"
echo "##########################################"
if [ -z "$travis" ]; then
    apt-get update -qq
    apt-get --option=Dpkg::options::=--force-confmiss \
        --option=Dpkg::options::=--force-confold \
        --option=Dpkg::options::=--force-unsafe-io \
        dist-upgrade --assume-yes --quiet
    apt-get autoremove --purge -qq
    apt-get autoclean -qq
fi

##################################
# Useful packages
##################################

echo "##########################################"
echo " Installing useful packages"
echo "##########################################"

apt-get \
    --option=Dpkg::options::=--force-confmiss \
    --option=Dpkg::options::=--force-confold \
    --assume-yes install haveged curl git unzip zip htop \
    nload nmon ntp gnupg gnupg2 wget pigz tree tzdata ccze --quiet

# set default ntp pools
if ! grep -q "time.cloudflare.com" /etc/systemd/timesyncd.conf; then
    sed -e 's/^#NTP=/NTP=time.cloudflare.com 0.ubuntu.pool.ntp.org 1.ubuntu.pool.ntp.org 2.ubuntu.pool.ntp.org 3.ubuntu.pool.ntp.org/' -i /etc/systemd/timesyncd.conf
    # enable ntp
    timedatectl set-ntp 1
fi

# increase history size
export HISTSIZE=10000

##################################
# clone repository
##################################
echo "###########################################"
echo " Cloning Ubuntu-nginx-web-server repository"
echo "###########################################"

if [ ! -d "$HOME/ubuntu-nginx-web-server" ]; then
    git clone https://github.com/VirtuBox/ubuntu-nginx-web-server.git "$HOME/ubuntu-nginx-web-server"
else
    git -C "$HOME/ubuntu-nginx-web-server" pull origin master
fi

##################################
# Secure SSH server
##################################

# get current ssh port
CURRENT_SSH_PORT=$(grep "Port" /etc/ssh/sshd_config | awk -F " " '{print $2}')

# download secure sshd_config
cp -f "$HOME/ubuntu-nginx-web-server/etc/ssh/sshd_config" /etc/ssh/sshd_config

if [ "$CURRENT_SSH_PORT" != "22" ]; then
    # change ssh default port
    sed -i "s/Port 22/Port $CURRENT_SSH_PORT/" /etc/ssh/sshd_config
fi

# restart ssh service
service ssh restart

##################################
# Sysctl tweaks +  open_files limits
##################################
echo "##########################################"
echo " Applying Linux Kernel tweaks"
echo "##########################################"

# download sysctl tweaks
if [ ! -f /etc/sysctl.d/60-plesk-tweaks.conf ]; then
    if [ "$plesk_srv_arch" = "x86_64" ]; then
        wget -qO /etc/sysctl.d/60-plesk-tweaks.conf \
            https://raw.githubusercontent.com/WordOps/WordOps/master/wo/cli/templates/sysctl.mustache
        if [ "$plesk_distro_version" = "bionic" ] || [ "$plesk_distro_version" = "focal" ] || [ "$plesk_distro_version" = "buster" ]; then
            modprobe tcp_bbr && echo 'tcp_bbr' >>/etc/modules-load.d/bbr.conf
            echo -e '\nnet.ipv4.tcp_congestion_control = bbr\nnet.ipv4.tcp_notsent_lowat = 16384' >>/etc/sysctl.d/60-plesk-tweaks.conf
        else
            modprobe tcp_htcp && echo 'tcp_htcp' >>/etc/modules-load.d/htcp.conf
            echo 'net.ipv4.tcp_congestion_control = htcp' >>/etc/sysctl.d/60-plesk-tweaks.conf
        fi
        # apply sysctl tweaks
        sysctl -eq -p /etc/sysctl.d/60-plesk-tweaks.conf
    fi
fi

if [ ! -x /opt/kernel-tweak.sh ]; then
    {
        # download and setup wo-kernel systemd service to apply kernel tweaks for netdata and redis on server startup
        wget -qO /opt/kernel-tweak.sh https://raw.githubusercontent.com/VirtuBox/kernel-tweak/master/kernel-tweak.sh
        chmod +x /opt/kernel-tweak.sh
        wget -qO /lib/systemd/system/kernel-tweak.service https://raw.githubusercontent.com/VirtuBox/kernel-tweak/master/kernel-tweak.service
        systemctl enable kernel-tweak.service
        systemctl start kernel-tweak.service
    } >>/tmp/plesk-install.log 2>&1
fi

# additional systcl configuration with network interface name
# get network interface names like eth0, ens18 or eno1
# for each interface found, add the following configuration to sysctl
NET_INTERFACES_WAN=$(ip -4 route get 8.8.8.8 | grep -oP "dev [^[:space:]]+ " | cut -d ' ' -f 2)
{
    echo ""
    echo "# do not autoconfigure IPv6 on $NET_INTERFACES_WAN"
    echo "net.ipv6.conf.$NET_INTERFACES_WAN.autoconf = 0"
    echo "net.ipv6.conf.$NET_INTERFACES_WAN.accept_ra = 0"
    echo "net.ipv6.conf.$NET_INTERFACES_WAN.accept_ra = 0"
    echo "net.ipv6.conf.$NET_INTERFACES_WAN.autoconf = 0"
    echo "net.ipv6.conf.$NET_INTERFACES_WAN.accept_ra_defrtr = 0"
} >>/etc/sysctl.d/60-ubuntu-nginx-web-server.conf

##################################
# Add MariaDB 10.3 repository
##################################

if [ "$mariadb_server_install" = "y" ]; then
    echo ""
    echo "##########################################"
    echo " Adding MariaDB $mariadb_version_install repository"
    echo "##########################################"
    {
        wget -qO mariadb_repo_setup https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
        chmod +x mariadb_repo_setup
        ./mariadb_repo_setup --mariadb-server-version=$mariadb_version_install --skip-maxscale -y
        rm mariadb_repo_setup
        apt-get update -qq
    } >>/tmp/plesk-install.log 2>&1
fi

##################################
# MariaDB 10.3 install
##################################

# install mariadb server non-interactive way
if [ "$mariadb_server_install" = "y" ]; then
    if [ ! -d /etc/mysql ]; then
        echo ""
        echo "##########################################"
        echo " Installing MariaDB server $mariadb_version_install"
        echo "##########################################"
        if [ "$mariadb_version_install" = "10.2" ] || [ "$mariadb_version_install" = "10.3" ]; then
            # generate random password
            MYSQL_ROOT_PASS=""
            echo "mariadb-server-${mariadb_version_install} mysql-server/root_password password ${MYSQL_ROOT_PASS}" | debconf-set-selections
            echo "mariadb-server-${mariadb_version_install} mysql-server/root_password_again password ${MYSQL_ROOT_PASS}" | debconf-set-selections
        fi
        # debconf-set-selections <<<"mariadb-server-${mariadb_version_install} mysql-server/root_password password ${MYSQL_ROOT_PASS}"
        # debconf-set-selections <<<"mariadb-server-${mariadb_version_install} mysql-server/root_password_again password ${MYSQL_ROOT_PASS}"
        # # install mariadb server
        apt-get install -qq mariadb-server # -qq implies -y --force-yes
        # mysql_secure_installation non-interactive way
        # remove anonymous users
        mysql -e "DROP USER ''@'localhost'" >/dev/null 2>&1
        mysql -e "DROP USER ''@'$(hostname)'" >/dev/null 2>&1
        # remove test database
        mysql -e "DROP DATABASE test" >/dev/null 2>&1
        # flush privileges
        mysql -e "FLUSH PRIVILEGES"
    fi
fi

##################################
# MariaDB tweaks
##################################

if [ "$mariadb_server_install" = "y" ]; then
    if [ "$mariadb_version_install" = "10.2" ] || [ "$mariadb_version_install" = "10.3" ]; then
        echo "##########################################"
        echo " Optimizing MariaDB configuration"
        echo "##########################################"

        cp /etc/mysql/my.cnf /etc/mysql/my.cnf.bak
        cp -f "$HOME/ubuntu-nginx-web-server/etc/mysql/my.cnf" /etc/mysql/my.cnf

        # stop mysql service to apply new InnoDB log file size
        service mysql stop

        # mv previous log file
        mv /var/lib/mysql/ib_logfile0 /var/lib/mysql/ib_logfile0.bak
        mv /var/lib/mysql/ib_logfile1 /var/lib/mysql/ib_logfile1.bak

        # increase mariadb open_files_limit
        echo -e '[Service]\nLimitNOFILE=500000' >/etc/systemd/system/mariadb.service.d/limits.conf

        # reload daemon
        systemctl daemon-reload

        # restart mysql
        service mysql start
    fi

fi

######### Do not edit below this line ###################
#########################################################

# Download Plesk AutoInstaller
if [ -z "$plesk_installed" ]; then
    echo "Downloading Plesk Auto-Installer"
    wget -O plesk-installer https://installer.plesk.com/plesk-installer
    echo

    # Make Installed Executable

    echo "Making Plesk Auto-Installer Executable"
    chmod +x ./plesk-installer
    echo

    # Install Plesk testing with Required Components

    echo "Starting Plesk Installation"
    if ! { ./plesk-installer install release --components panel bind fail2ban \
        l10n pmm mysqlgroup repair-kit \
        roundcube spamassassin postfix dovecot \
        proftpd awstats mod_fcgid webservers git \
        nginx php7.2 php7.3 php7.4 config-troubleshooter \
        psa-firewall wp-toolkit letsencrypt \
        imunifyav sslit; } >>/tmp/plesk-install.log 2>&1; then
        echo
        echo "An error occurred! The installation of Plesk failed. Please see logged lines above for error handling!"
        tail -f 50 /tmp/plesk-install.log | ccze -A
        exit 1
    fi
    #./plesk-installer --select-product-id plesk --select-release-latest --installation-type Recommended

    if [ "$plesk_kvm_detec" = "kvm" ]; then
        # Enable VPS Optimized Mode
        echo "Enable VPS Optimized Mode"
        plesk bin vps_optimized --turn-on >>/tmp/plesk-install.log 2>&1
        echo
    fi

    # If Ruby and NodeJS are needed then run install Plesk using the following command:
    # ./plesk-installer install plesk --preset Recommended --with fail2ban modsecurity spamassassin mailman psa-firewall pmm health-monitor passenger ruby nodejs gems-preecho
    echo ""
    echo ""

    # Initalize Plesk before Additional Configuration
    # https://docs.plesk.com/en-US/onyx/cli-linux/using-command-line-utilities/init_conf-server-configuration.37843/

    # Install Plesk Activation Key if provided
    # https://docs.plesk.com/en-US/onyx/cli-linux/using-command-line-utilities/license-license-keys.71029/

    export PSA_PASSWORD=$plesk_pass

    if [ -n "$activation_key" ]; then
        echo "Starting initialization process of your Plesk server"
        /usr/sbin/plesk bin init_conf --init -email "$plesk_email" -passwd "" -name "$plesk_name" -license_agreed "$agreement"
        echo "Installing Plesk Activation Code"
        /usr/sbin/plesk bin license --install "$activation_key"
        echo
    else
        echo "Starting initialization process of your Plesk server"
        /usr/sbin/plesk bin init_conf --init -email "$plesk_email" -passwd "" -name "$plesk_name" -license_agreed "$agreement" -trial_license true
    fi

    # Configure Service Provider View On

    if [ "$plesk_ui" = "spv" ]; then
        echo "Setting to Service Provider View"
        /usr/sbin/plesk bin poweruser --off
        echo
    else
        echo "Setting to Power user View"
        /usr/sbin/plesk bin poweruser --on
        echo
    fi

    # Make sure Plesk UI and Plesk Update ports are allowed

    echo "Setting Firewall to allow proper ports."
    {
        iptables -I INPUT -p tcp --dport 21 -j ACCEPT
        iptables -I INPUT -p tcp --dport 22 -j ACCEPT
        iptables -I INPUT -p tcp --dport 80 -j ACCEPT
        iptables -I INPUT -p tcp --dport 443 -j ACCEPT
        iptables -I INPUT -p tcp --dport 465 -j ACCEPT
        iptables -I INPUT -p tcp --dport 993 -j ACCEPT
        iptables -I INPUT -p tcp --dport 995 -j ACCEPT
        iptables -I INPUT -p tcp --dport 8443 -j ACCEPT
        iptables -I INPUT -p tcp --dport 8447 -j ACCEPT
        iptables -I INPUT -p tcp --dport 8880 -j ACCEPT
    } >>/tmp/plesk-install.log 2>&1

    echo
fi
# Enable Modsecurity
# https://docs.plesk.com/en-US/onyx/administrator-guide/server-administration/web-application-firewall-modsecurity.73383/

#echo "Turning on Modsecurity WAF Rules"
#plesk bin server_pref --update-web-app-firewall -waf-rule-engine on -waf-rule-set tortix -waf-rule-set-update-period daily -waf-config-preset tradeoff
#echo

# Enable Fail2Ban and Jails
# https://docs.plesk.com/en-US/onyx/cli-linux/using-command-line-utilities/ip_ban-ip-address-banning-fail2ban.73594/

if [ "$fail2ban" = "yes" ]; then
    echo "Configuring Fail2Ban and its Jails"
    /usr/sbin/plesk bin ip_ban --enable
    /usr/sbin/plesk bin ip_ban --enable-jails ssh
    /usr/sbin/plesk bin ip_ban --enable-jails recidive
    /usr/sbin/plesk bin ip_ban --enable-jails plesk-proftpd
    /usr/sbin/plesk bin ip_ban --enable-jails plesk-postfix
    /usr/sbin/plesk bin ip_ban --enable-jails plesk-dovecot
    /usr/sbin/plesk bin ip_ban --enable-jails plesk-roundcube
    /usr/sbin/plesk bin ip_ban --enable-jails plesk-apache-badbot
    /usr/sbin/plesk bin ip_ban --enable-jails plesk-panel
    /usr/sbin/plesk bin ip_ban --enable-jails plesk-wordpress
    /usr/sbin/plesk bin ip_ban --enable-jails plesk-apache
    echo
fi

# Turn on http2
# https://docs.plesk.com/en-US/onyx/administrator-guide/web-servers/apache-and-nginx-web-servers-linux/http2-support-in-plesk.76461/

if [ "$http2" = "yes" ]; then
    echo "Activating http2"
    /usr/sbin/plesk bin http2_pref --enable
    echo
fi

# Enable PCI Compliance
if [ "$pci_compliance" = "yes" ]; then
    /usr/sbin/plesk sbin pci_compliance_resolver --enable all
fi

# Install Bundle Extensions
# https://docs.plesk.com/en-US/onyx/cli-linux/using-command-line-utilities/extension-extensions.71031/

echo "Installing Requested Plesk Extensions"
echo
echo "Installing SEO Toolkit"
/usr/sbin/plesk bin extension --install-url https://ext.plesk.com/packages/2ae9cd0b-bc5c-4464-a12d-bd882c651392-xovi/download
echo
echo "Installing Revisium Antivirus for Websites"
/usr/sbin/plesk bin extension --install-url https://ext.plesk.com/packages/b71916cf-614e-4b11-9644-a5fe82060aaf-revisium-antivirus/download
echo ""
echo "Installing Plesk Migration Manager"
/usr/sbin/plesk bin extension --install-url https://ext.plesk.com/packages/bebc4866-d171-45fb-91a6-4b139b8c9a1b-panel-migrator/download
echo
echo "Installing Code Editor"
/usr/sbin/plesk bin extension --install-url https://ext.plesk.com/packages/e789f164-5896-4544-ab72-594632bcea01-rich-editor/download
echo
echo "Installing MagicSpam"
/usr/sbin/plesk bin extension --install-url https://ext.plesk.com/packages/b49f9b1b-e8cf-41e1-bd59-4509d92891f7-magicspam/download
echo
echo "Installing Panel.ini Extension"
/usr/sbin/plesk bin extension --install-url https://ext.plesk.com/packages/05bdda39-792b-441c-9e93-76a6ab89c85a-panel-ini-editor/download
echo
echo "Installing Schedule Backup list Extension"
/usr/sbin/plesk bin extension --install-url https://ext.plesk.com/packages/17ffcf2a-8e8f-4cb2-9265-1543ff530984-scheduled-backups-list/download
echo
echo "Set custom panel.ini config"
wget https://raw.githubusercontent.com/VirtuBox/ubuntu-plesk-onyx/master/usr/local/psa/admin/conf/panel.ini -O /usr/local/psa/admin/conf/panel.ini
echo

# Prepair for Cloning
# https://docs.plesk.com/en-US/onyx/cli-linux/using-command-line-utilities/cloning-server-cloning-settings.71035/

if [ "$clone" = "on" ]; then
    echo "Setting Plesk Cloning feature."
    /usr/sbin/plesk bin cloning --update -prepare-public-image true -reset-license true -skip-update true
    echo "Plesk initialization will be wiped on next boot. Ready for Cloning."
else
    echo "Here is your login"
    /usr/sbin/plesk login
fi

echo
echo "Your Ubuntu Plesk Server is ready."
echo "Give ubuntu-plesk-server a GitHub star : https://github.com/VirtuBox/ubuntu-plesk-server"
echo
