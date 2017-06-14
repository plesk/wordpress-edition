#!/bin/bash

################################################################################
##          Installation script for Plesk WordPress Server                    ##
################################################################################

# Edit variables for Plesk pre-configuration

hostname='cp.domain.tst'
email='admin@test.tst'
passwd='CookBook123'
name='admin'
company='Plesk Sample Company'
phone='123-123-1234'
address='123_street'
city='NY'
state='NY'
zip='12345'
country='US'
agreement=true
ip_type=shared

# Plesk Activation Code - provide proper license for initialization, it will be replaced after cloning
# leave as null if not providing key
activation_key=

# Plesk UI View - can be set to Service Provider View (spv) or Power User View (puv)
plesk_ui=puv

# Turn on Fail2Ban, yes or no, Keep in mind you need to provide temp license for initialization for this to work
fail2ban=yes

# Turn on http2
http2=yes

# Test to make sure all initialization values are set

if [[ -z $activation_key ]]; then
echo 'Please provide a proper Plesk Activation Code (Bundle License).'
  exit 1
fi

if [[ -z $hostname || -z $email || -z $passwd || -z $name || -z $company || -z $phone || -z $address || -z $city || -z $state || -z $zip || -z $country || -z $agreement || -z $ip_type ]]; then
  echo 'One or more variables are undefined. Please check your initialization values.'
  exit 1
fi

echo "Plesk initialization values are all assigned. We are good so far."
echo

######### Do not edit below this line ###################
#########################################################

# Download Plesk AutoInstaller

echo "Downloading Plesk Auto-Installer"
wget https://installer.plesk.com/plesk-installer
echo

# Make Installed Executable

echo "Making Plesk Auto-Installer Executable"
chmod +x ./plesk-installer
echo

# Install Plesk with Required Components

echo "Starting Plesk Installation"
./plesk-installer install plesk --preset Full --with panel bind fail2ban l10n pmm mysqlgroup roundcube kav spamassassin selinux postfix dovecot proftpd awstats modsecurity mod_fcgid webservers php7.1 php5.6 config-troubleshooter psa-firewall cloudflare heavy-metal-skin wp-toolkit security-advisor letsencrypt
echo
echo

# Initalize Plesk before Additional Configuration

echo "Starting initialization process of your Plesk server"
plesk bin init_conf --init -email $email -passwd $passwd -company $company -name $name -phone $phone -address $address -city $city -state $state -zip $zip -country $country -license_agreed $agreement -ip-type $ip_type
echo

# Install Plesk Activation Key if provided

if [[ -n "$activation_key" ]]; then
  echo "Installing Plesk Activation Code"
  plesk bin license --install $activation_key
  echo
fi

# Configure Service Provider View On

if [ "$pleskui" = "spv" ]; then
    echo "Setting to Service Provider View"
    plesk bin poweruser --off
    echo
else
    echo "Setting to Power user View"
    plesk bin poweruser --on
    echo
fi

# Make sure Plesk UI and Plesk Update ports are allowed

echo "Setting Firewall to allow proper ports."
iptables -I INPUT -p tcp --dport 21 -j ACCEPT
iptables -I INPUT -p tcp --dport 22 -j ACCEPT
iptables -I INPUT -p tcp --dport 25 -j ACCEPT
iptables -I INPUT -p tcp --dport 80 -j ACCEPT
iptables -I INPUT -p tcp --dport 110 -j ACCEPT
iptables -I INPUT -p tcp --dport 143 -j ACCEPT
iptables -I INPUT -p tcp --dport 443 -j ACCEPT
iptables -I INPUT -p tcp --dport 465 -j ACCEPT
iptables -I INPUT -p tcp --dport 993 -j ACCEPT
iptables -I INPUT -p tcp --dport 995 -j ACCEPT
iptables -I INPUT -p tcp --dport 8443 -j ACCEPT
iptables -I INPUT -p tcp --dport 8447 -j ACCEPT
iptables -I INPUT -p tcp --dport 8880 -j ACCEPT
echo

# Enable Modsecurity

echo "Turning on Modsecurity WAF Rules"
plesk sbin modsecurity_ctl --enable --enable-ruleset atomic
echo

# Enable Fail2Ban and Jails

if [ "$fail2ban" = "yes" ]; then
  echo "Configuring Fail2Ban and its Jails"
  plesk bin ip_ban --enable
  plesk bin ip_ban --enable-jails ssh
  plesk bin ip_ban --enable-jails recidive
  plesk bin ip_ban --enable-jails modsecurity
  plesk bin ip_ban --enable-jails plesk-proftpd
  plesk bin ip_ban --enable-jails plesk-postfix
  plesk bin ip_ban --enable-jails plesk-dovecot
  plesk bin ip_ban --enable-jails plesk-roundcube
  plesk bin ip_ban --enable-jails plesk-roundcube
  plesk bin ip_ban --enable-jails plesk-apache-badbot
  plesk bin ip_ban --enable-jails plesk-panel
  plesk bin ip_ban --enable-jails plesk-wordpress
  echo
fi

# Turn on http2

if [ "$http2" = "yes" ]; then
  echo "Activating http2"
  /usr/sbin/plesk bin http2_pref --enable
  echo
fi

# Install Bundle Extensions

echo "Installing Requested Plesk Extensions"
echo "Installing Route 53"
plesk bin extension --install-url https://ext.plesk.com/packages/ed1860ee-45c5-4e2b-b6b7-44e5da69dca5-route53/download
echo
echo "Installing Security Advisor"
plesk bin extension --install-url https://ext.plesk.com/packages/6bcc01cf-d7bb-4e6a-9db8-dd1826dcad8f-security-advisor/download
echo
echo "Installing Google Pagespeed Insights"
plesk bin extension --install-url https://ext.plesk.com/packages/3d2639e6-64a9-43fe-a990-c873b6b3ec66-pagespeed-insights/download
echo
echo "Installing Addendio - WordPress Plugin and Themes"
plesk bin extension --install-url https://ext.plesk.com/packages/250589ff-8081-4c30-b9ca-66539e025c27-addendio-wordpress/download
echo
echo "Installing Datagrid VCTR reliability and vulnerability scanner"
plesk bin extension --install-url https://ext.plesk.com/packages/e757450e-40a5-44e5-a35d-8c4c50671019-dgri/download
echo
echo "Installing LetsEncrypt"
plesk bin extension --install-url https://ext.plesk.com/packages/f6847e61-33a7-4104-8dc9-d26a0183a8dd-letsencrypt/download
echo
echo "Installing Plesk Migration Manager"
plesk bin extension --install-url https://ext.plesk.com/packages/bebc4866-d171-45fb-91a6-4b139b8c9a1b-panel-migrator/download
echo
echo "Installing Welcome Extension"
plesk bin extension --install-url https://github.com/plesk/wordpress-server/raw/master/ext-welcome-wp_v1.0.0-9.zip
echo


# Prepair for Cloning

echo "Setting Plesk Cloning feature."
plesk bin cloning --update -prepare-public-image true
echo "Plesk initialization will be wiped on next boot. Ready for Cloning."
echo
echo "Your Plesk WordPress Server image is complete."
echo "Thank you for using the WordPress Server Cookbook"
echo
echo
