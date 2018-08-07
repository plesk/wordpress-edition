#!/bin/bash

################################################################################
##          Installation script for Plesk WordPress Edition                   ##
################################################################################

# Edit variables for Plesk pre-configuration

email='admin@test.tst'
passwd='CookBook123'
name='admin'
agreement=true

# Plesk Activation Code - provide proper license for initialization, it will be replaced after cloning
# leave as null if not providing key
activation_key=$1

# Plesk UI View - can be set to Service Provider View (spv) or Power User View (puv)
plesk_ui=spv

# Turn on Fail2Ban, yes or no, Keep in mind you need to provide temp license for initialization for this to work
fail2ban=yes

# Turn on http2
http2=yes

# Turn on Cloning - Set to "on" if this it to make a Golden Image, set to "off" if for remote installation
clone=off

# Test to make sure all initialization values are set

if [[ -z $activation_key ]]; then
echo 'Please provide a proper Plesk Activation Code (Bundle License).'
  exit 1
fi

if [[ -z $email || -z $passwd || -z $name || -z $agreement ]]; then
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
./plesk-installer install plesk --preset Recommended --with fail2ban modsecurity spamassassin mailman psa-firewall pmm health-monitor
OUT=$?
if [ $OUT -ne 0 ];then
  echo
  echo "Plesk Installation Failed. Plese see logged lines above for error handling"
  exit 1
fi

# If Ruby and NodeJS are needed then run install Plesk using the following command:
# ./plesk-installer install plesk --preset Recommended --with fail2ban modsecurity spamassassin mailman psa-firewall pmm health-monitor passenger ruby nodejs gems-preecho
echo
echo

# Initalize Plesk before Additional Configuration
# https://docs.plesk.com/en-US/onyx/cli-linux/using-command-line-utilities/init_conf-server-configuration.37843/

echo "Starting initialization process of your Plesk server"
plesk bin init_conf --init -email $email -passwd $passwd -name $name -license_agreed $agreement 
plesk bin settings --set solution_type="wordpress"
echo

# Install Plesk Activation Key if provided
# https://docs.plesk.com/en-US/onyx/cli-linux/using-command-line-utilities/license-license-keys.71029/

if [[ -n "$activation_key" ]]; then
  echo "Installing Plesk Activation Code"
  plesk bin license --install $activation_key
  echo
fi

# Configure Service Provider View On

if [ "$plesk_ui" = "spv" ]; then
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
# https://docs.plesk.com/en-US/onyx/administrator-guide/server-administration/web-application-firewall-modsecurity.73383/

echo "Turning on Modsecurity WAF Rules"
plesk bin server_pref --update-web-app-firewall -waf-rule-engine on -waf-rule-set tortix -waf-rule-set-update-period daily -waf-config-preset tradeoff
echo

# Enable Fail2Ban and Jails
# https://docs.plesk.com/en-US/onyx/cli-linux/using-command-line-utilities/ip_ban-ip-address-banning-fail2ban.73594/

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
  plesk bin ip_ban --enable-jails plesk-apache-badbot
  plesk bin ip_ban --enable-jails plesk-panel
  plesk bin ip_ban --enable-jails plesk-wordpress
  plesk bin ip_ban --enable-jails plesk-apache
  plesk bin ip_ban --enable-jails plesk-horde
  echo
fi

# Turn on http2
# https://docs.plesk.com/en-US/onyx/administrator-guide/web-servers/apache-and-nginx-web-servers-linux/http2-support-in-plesk.76461/

if [ "$http2" = "yes" ]; then
  echo "Activating http2"
  /usr/sbin/plesk bin http2_pref --enable
  echo
fi

# Install Bundle Extensions
# https://docs.plesk.com/en-US/onyx/cli-linux/using-command-line-utilities/extension-extensions.71031/

echo "Installing Requested Plesk Extensions"
echo
echo "Installing SEO Toolkit"
plesk bin extension --install-url https://ext.plesk.com/packages/2ae9cd0b-bc5c-4464-a12d-bd882c651392-xovi/download
echo
echo "Installing BoldGrid"
plesk bin extension --install-url https://ext.plesk.com/packages/e4736f87-ba7e-4601-a403-7c82682ef07d-boldgrid/download
echo
echo "Installing Backup to Cloud extensions"
plesk bin extension --install-url https://ext.plesk.com/packages/9f3b75b3-d04d-44fe-a8fa-7e2b1635c2e1-dropbox-backup/download
plesk bin extension --install-url https://ext.plesk.com/packages/52fd6315-22a4-48b8-959d-b2f1fd737d11-google-drive-backup/download
plesk bin extension --install-url https://ext.plesk.com/packages/8762049b-870e-47cb-ba14-9f055b99b508-s3-backup/download
plesk bin extension --install-url https://ext.plesk.com/packages/a8e5ad9c-a254-4bcf-8ae4-5440f13a88ad-one-drive-backup/download
echo
echo "Installing Speed Kit"
plesk bin extension --install-url https://ext.plesk.com/packages/11e1bf5f-a0df-48c6-8761-e890ff4e906c-baqend/download
echo
echo "Installing Revisium Antivirus for Websites"
plesk bin extension --install-url https://ext.plesk.com/packages/b71916cf-614e-4b11-9644-a5fe82060aaf-revisium-antivirus/download
echo
echo "Installing Google Pagespeed Insights"
plesk bin extension --install-url https://ext.plesk.com/packages/3d2639e6-64a9-43fe-a990-c873b6b3ec66-pagespeed-insights/download
echo
echo "Installing Uptime Robot"
plesk bin extension --install-url https://ext.plesk.com/packages/7d37cfde-f133-4085-91ea-d5399862321b-uptime-robot/download
echo
echo "Installing Sucuri Site Scanner"
plesk bin extension --install-url https://ext.plesk.com/packages/2d5b423b-9104-40f2-9286-a75a6debd43f-sucuri-scanner/download
echo 
echo "Installing Domain Connect"
plesk bin extension --install-url https://ext.plesk.com/packages/3a36f828-e477-4600-be33-48c21e351c9a-domain-connect/download
echo
echo "Installing Welcome Guide"
plesk bin extension --install-url https://ext.plesk.com/packages/39eb8f3d-0d9a-4605-a42a-c37ca5809415-welcome/download
echo
echo "Enabling Welcome Guide for the Plesk WordPress Edition"
plesk ext welcome --select -preset wordpress
echo 



# Prepair for Cloning
# https://docs.plesk.com/en-US/onyx/cli-linux/using-command-line-utilities/cloning-server-cloning-settings.71035/

if [ "$clone" = "on" ]; then
	echo "Setting Plesk Cloning feature."
	plesk bin cloning --update -prepare-public-image true -reset-lincese true -skip-update true
	echo "Plesk initialization will be wiped on next boot. Ready for Cloning."
else
  echo "Here is your login"
  plesk login
fi

echo
echo "Your Plesk WordPress Edition is complete."
echo "Thank you for using the WordPress Edition Cookbook"
echo
