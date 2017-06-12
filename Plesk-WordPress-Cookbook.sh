#!/bin/bash

#Plesk 
#Edit variables for Plesk Initialization

hostname="cp.domain.tst"
email="admin@test.tst"
passwd=CookBook123
aname=“admin”
company=Cookbook
phone="123-123-1234"
address=“123_street”
city=NY
state=NY
zip=12345
country=US
agreement=true
iptype=shared

#Plesk UI View - can be set to Service Provider View (spv) or Power User View (puv)
pleskui=puv

#Turn on Fail2Ban, yes or no, Keep in mind you need to provide temp license for initialization for this to work
fail2ban=yes

#Plesk Activation Code - provide proper license for initialization, it will be replaced after cloning
#leave as null if not providing key
activation_key=<put your activation code here>
#Turn on http2
http2=yes

######### Do not edit below this line ###################
#########################################################

#Download Plesk AutoInstaller

wget https://installer.plesk.com/plesk-installer



#Make Installed Executable

chmod +x ./plesk-installer




#Install Plesk with Required Components


./plesk-installer install plesk --preset Full --without resctrl sitebuilder drweb mailman java psa-vpn psa-fileserver watchdog magicspam health-monitor



#Initalize Plesk before Additional Configuration


echo "Starting initialization process of your Plesk server"
plesk bin init_conf --init -email $email -passwd $passwd -company $company -name $name -phone $phone -address $address -city $city -state $state -zip $zip -country $country -license_agreed $agreement -ip-type $iptype


#Install Plesk Activation Key if provided

if [ “$activation_key” != “null” ]; then

echo "Installing Plesk Activation Code"
plesk bin license --install $activation_key
echo "  "

fi



#Configure Service Provider View On
if [ "$pleskui" = "spv" ]; then
    echo "Setting to Service Provider View"
    /usr/sbin/plesk bin poweruser --off
    echo "  "
else
    echo "Setting to Power user View"
    /usr/sbin/plesk bin poweruser --on
    echo "  "
fi


#Make sure Plesk UI and Plesk Update ports are allowed

echo "Setting Firewall to allow Ports 8443 and 8447"
iptables -I INPUT -p tcp --dport 8443 -j ACCEPT
iptables -I INPUT -p tcp --dport 8447 -j ACCEPT
echo "  "

#Enable Modsecurity

echo "Turning on Modsecurity WAF Rules"
plesk sbin modsecurity_ctl --enable --enable-ruleset atomic
echo "  "


#Enable Fail2Ban and Jails


if [ “$fail2ban” = “yes” ]; then

echo "Configuring Fail2Ban and its Jails"
/usr/sbin/plesk bin ip_ban --enable
/usr/sbin/plesk bin ip_ban --enable-jails ssh
/usr/sbin/plesk bin ip_ban --enable-jails recidive
/usr/sbin/plesk bin ip_ban --enable-jails modsecurity
/usr/sbin/plesk bin ip_ban --enable-jails plesk-proftpd
/usr/sbin/plesk bin ip_ban --enable-jails plesk-postfix
/usr/sbin/plesk bin ip_ban --enable-jails plesk-dovecot
/usr/sbin/plesk bin ip_ban --enable-jails plesk-roundcube
/usr/sbin/plesk bin ip_ban --enable-jails plesk-roundcube
/usr/sbin/plesk bin ip_ban --enable-jails plesk-apache-badbot
/usr/sbin/plesk bin ip_ban --enable-jails plesk-panel
/usr/sbin/plesk bin ip_ban --enable-jails plesk-wordpress
echo "  "

fi


#Turn on http2

if [ “$http2” = “yes” ]; then
echo "Activating http2"
/usr/sbin/plesk bin http2_pref --enable
echo "  "
fi


#Install Bundle Extensions

echo "Installing Requested Plesk Extensions"
echo "Installing Route 53"
plesk bin extension --install-url https://ext.plesk.com/packages/ed1860ee-45c5-4e2b-b6b7-44e5da69dca5-route53/download?2.3-0
echo "  "
echo "Installing Security Advisor"
plesk bin extension --install-url https://ext.plesk.com/packages/6bcc01cf-d7bb-4e6a-9db8-dd1826dcad8f-security-advisor/download?1.4.0-4
echo "  "
echo "Installing Google Pagespeed Insights"
plesk bin extension --install-url https://ext.plesk.com/packages/3d2639e6-64a9-43fe-a990-c873b6b3ec66-pagespeed-insights/download?1.0.0-6
echo "  "
echo "Installing Addendio - WordPress Plugin and Themes"
plesk bin extension --install-url https://ext.plesk.com/packages/250589ff-8081-4c30-b9ca-66539e025c27-addendio-wordpress/download?1.2.0-73
echo "  "
echo "Installing Datagrid VCTR reliability and vulnerability scanner"
plesk bin extension --install-url https://ext.plesk.com/packages/e757450e-40a5-44e5-a35d-8c4c50671019-dgri/download?2.1-0
echo "  "
echo "Installing LetsEncrypt"
plesk bin extension --install-url https://ext.plesk.com/packages/f6847e61-33a7-4104-8dc9-d26a0183a8dd-letsencrypt/download?2.1.0-48
echo "  "
echo "Installing Plesk Migration Manager"
plesk bin extension --install-url https://ext.plesk.com/packages/bebc4866-d171-45fb-91a6-4b139b8c9a1b-panel-migrator/download?2.9.2-0
echo "  "


#Prepair do Clonging

echo "Setting Plesk Cloning feature."
plesk bin cloning --update -prepare-public-image true
echo "Plesk Initialization will be wiped on next boot. Ready for Cloning."


echo ""
echo "Your Plesk WordPress Bundle Image is complete."
echo "Thank you for using the Plesk Business Server Cookbook"
echo "  "
echo "  "
