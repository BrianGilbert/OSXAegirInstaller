#!/bin/sh
# Written by Brian Gilbert @BrianGilbert_ https://github.com/BrianGilbert
# of Realityloop @Realityloop http://realitylop.com/
# I'm by no means a bash scripter, please submit pull requests/issues for improvements. :)

# Set some variables for username installing aegir and the OS X version
username=${USER-$LOGNAME} #`ps -o user= $(ps -o ppid= $PPID)`
osx=`sw_vers -productVersion`

# Make sure that the script wasn't run as root.
if [ $username = "root" ] ; then
  printf "> This script should not be run as sudo or root. exiting.\n"
  exit
fi

# Check Aegir isn't already installed.
if [ -e "/var/aegir/config/includes/global.inc" ] ; then
  printf "> You already have aegir installed.. exiting.\n"
  exit # Remove this line when uninstall block below is fixed.
  # Possibly I'll allow reinstallations in the future..
  #
  # printf "Should I remove it and do a clean install? [Y/n]\n"
  # read CLEAN
  # if [ $CLEAN != n -o $CLEAN != N ] ; then
  #   printf "There is no turning back..\nThis will unusinstall aegir and all related homebrew compononets before running a clean install, are you sure? [Y/n]\n"
  #   read FORSURE
  #   if [ $FORSURE != n -o $FORSURE != N ] ; then
  #     printf "Don't say I didn't warn you, cleaning everything before running clean install..\n"

  #     printf "Stopping and deleting any services that are already installed..\n"
  #     if [ -e "/Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist" ] ; then
  #       launchctl unload -w /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist
  #       rm /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist
  #     fi

  #     if [ -e "/Library/LaunchDaemons/homebrew.mxcl.nginx.plist" ] ; then
  #     sudo -u $USERNAME launchctl unload -w /Library/LaunchDaemons/homebrew.mxcl.nginx.plist
  #     sudo -u $USERNAME rm /Library/LaunchDaemons/homebrew.mxcl.nginx.plist
  #     fi

  #     if [ -e "~/Library/LaunchAgents/homebrew.mxcl.mariadb.plist" ] ; then
  #     sudo -u $USERNAME launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.mariadb.plist
  #     sudo -u $USERNAME rm ~/Library/LaunchAgents/homebrew.mxcl.mariadb.plist
  #     fi

  #     if [ -e "~/Library/LaunchAgents/homebrew-php.josegonzalez.php53.plist" ] ; then
  #     sudo -u $USERNAME launchctl unload -w ~/Library/LaunchAgents/homebrew-php.josegonzalez.php53.plist
  #     sudo -u $USERNAME rm ~/Library/LaunchAgents/homebrew-php.josegonzalez.php53.plist
  #     fi
  #     printf "Removing Aegir folder..\n"
  #     rm -rf /var/aegir
  #     printf "Uninstalling related brews..\n"
  #     sudo -u $USERNAME brew uninstall php53-uploadprogress
  #     sudo -u $USERNAME brew uninstall php53-xdebug
  #     sudo -u $USERNAME brew uninstall php53-xhprof
  #     sudo -u $USERNAME brew uninstall php53
  #     sudo -u $USERNAME brew uninstall nginx
  #     sudo -u $USERNAME brew uninstall pcre geoip
  #     sudo -u $USERNAME brew uninstall dnsmasq
  #     sudo -u $USERNAME brew uninstall drush
  #     sudo -u $USERNAME brew uninstall gzip
  #     sudo -u $USERNAME brew uninstall wget
  #     printf "Removing related configurations..\n"
  #     rm -rf /usr/local/etc/nginx
  #     rm -rf /usr/local/etc/php
  #     rm -rf /usr/local/etc/dnsmasq.conf
  #   else
  #     printf "Exiting..\n"
  #     exit
  #   fi
  # else
  #   printf "Exiting..\n"
  #   exit
  # fi
fi

clear
echo "########
# You do need to watch this script as there are several places
# where input is required hopefully it will become set and
# forget at some stage.
#
# You will also need the following information during this script:
# -a gmail account that is configured to allow remote smtp access
# -the password for the gmail account address
# -an email address to receive notifications from aegir
# -attention to what is being requested via the script
########
# What you would like your machines hostname to be?
# It must end in .ld, eg: realityloop.ld
########"
read hname
printf "\n> Your hostname will be set to: $hname \n"

echo "########
# I can also setup ApacheSolr which is best used in conjunction with:
# https://drupal.org/project/search_api_solr
# Set up solr [Y/N]:
########"
read solr

if [ $solr != n -o $solr != N ] ; then
  echo "########
# Do you want solr to run automatically on boot [Y/n]:
########"
  read solrboot
fi

echo "
########
# What address should aegirs email notifications get sent to?
########"
read email

echo "########
# I'd like to set up postfix so you receive emails from Aegir
#
# !!! This has only been tested with gmail accounts !!!
#
# If you don't do it now you will need to configure mail sending yourself:
# http://rl.cm/13ujhJp
#
# Do you have a gmail account you can use? [Y/n]:
########"
read gmail
if [ $gmail != n -o $gmail != N ] ; then
  printf "\nOK, I'll attempt to set up postfix..\n"
  echo "########
# Whats the full gmail address? (eg. aegir@gmail.com)
########"
  read gmailaddress
  echo "
########
# What is the account password?
########"
  read gmailpass

  #setup mail sending
  printf "> No time like the present, lets set up postfix now..\n"
  sudo launchctl unload /System/Library/LaunchDaemons/org.postfix.master.plist
  echo "smtp.gmail.com:587 $gmailaddress:$gmailpass"  | sudo tee -a  /etc/postfix/sasl_passwd
  sudo postmap /etc/postfix/sasl_passwd
  sudo cp /etc/postfix/main.cf /etc/postfix/main.cf.orig
  echo "
myhostname =" $hname"

# Minimum Postfix-specific configurations.
mydomain_fallback = localhost
mail_owner = _postfix
setgid_group = _postdrop
relayhost=smtp.gmail.com:587

# Enable SASL authentication in the Postfix SMTP client.
smtp_sasl_auth_enable=yes
smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options=

# Enable Transport Layer Security (TLS), i.e. SSL.
smtp_use_tls=yes
smtp_tls_security_level=encrypt
tls_random_source=dev:/dev/urandom" | sudo tee -a  /etc/postfix/main.cf
  echo  "$email" >> ~/.forward
  sudo launchctl load -w /System/Library/LaunchDaemons/org.postfix.master.plist
else
  printf "\n> Mail sending from aegir won't actually work until you configure postfix properly..\n"
  printf "\n> See: http://realityloop.com/blog/2011/06/05/os-x-ditching-mamp-pro-part-2-gmail-email-relay\n"
fi

printf "> Checking OS version..\n"
if [ $osx = 10.8.4 -o $osx = 10.8.5 -o $osx = 10.9 ] ; then
  printf "> Your OS is new enough, so let's go!\n"
fi

printf "> Making sure the Command Line Tools are installed..\n"
xcode-select --install

printf "> Checking if Homebrew is installed..\n"
if type "brew" > /dev/null 2>&1; then
  printf "> Affirmative! Lets make sure everything is up to date..\n"
  printf "> Just so you know, this may throw a few warnings..\n"
  export PATH=/usr/local/bin:/usr/local/sbin:$PATH
  brew prune
  brew update
  brew doctor
else
  printf "> Nope! Installing Homebrew now..\n"
  ruby -e "$(curl -fsSL https://raw.github.com/mxcl/homebrew/go)"
  echo  'export PATH=/usr/local/bin:/usr/local/sbin:$PATH' >> ~/.bashrc
  echo  'export PATH=/usr/local/bin:/usr/local/sbin:$PATH' >> ~/.zshrc
  export PATH=/usr/local/bin:/usr/local/sbin:$PATH
  brew doctor
fi

# Tap required kegs
printf "> Now we'll tap some extra kegs we need..\n"
printf "> I will throw errors if they're already tapped, nothing to worry about..\n"
brew tap homebrew/dupes
brew tap josegonzalez/homebrew-php

# Install required formula's
printf "> Installing required brew formulas..\n"
printf "> Installing gcc..\n"
brew install apple-gcc42
printf "> Installing wget..\n"
brew install wget
printf "> Installing gzip..\n"
brew install gzip
printf "> Installing drush..\n"
brew install drush
printf "> Installing dnsmasq..\n"
brew install dnsmasq
printf "> Configuring dnsmasq..\n"
mkdir -p /usr/local/etc

# Configure dnsmasq
if [ -e "/usr/local/etc/dnsmasq.conf" ] ; then
  printf "> You already have a dnsmasq.conf file..\n> So this all works proerly I'm going to delete and recreate it..\n"
  rm /usr/local/etc/dnsmasq.conf
fi

printf "> Setting dnsmasq config..\n"
cp $(brew --prefix dnsmasq)/dnsmasq.conf.example /usr/local/etc/dnsmasq.conf
echo '# Edited by MEMPAE script' | cat - /usr/local/etc/dnsmasq.conf > temp && mv temp /usr/local/etc/dnsmasq.conf
echo "resolv-file=/etc/resolv.dnsmasq.conf" >> /usr/local/etc/dnsmasq.conf
echo "address=/.ld/127.0.0.1" >> /usr/local/etc/dnsmasq.conf
echo "listen-address=127.0.0.1" >> /usr/local/etc/dnsmasq.conf
echo "addn-hosts=/usr/local/etc/dnsmasq.hosts" >> /usr/local/etc/dnsmasq.conf
touch /usr/local/etc/dnsmasq.hosts

if [ -e "/etc/resolv.dnsmasq.conf" ] ; then
  printf "> You already have a resolv.conf set..\n> So this all works proerly I'm going to delete and recreate it..\n"
  sudo rm /etc/resolv.dnsmasq.conf
fi

printf "> Setting OpenDNS and Google DNS servers as fallbacks..\n"
sudo sh -c 'echo "# OpenDNS IPv6:
nameserver 2620:0:ccd::2
nameserver 2620:0:ccc::2
# Google IPv6:
nameserver 2001:4860:4860::8888
nameserver 2001:4860:4860::8844
# OpenDNS:
nameserver 208.67.222.222
nameserver 208.67.220.220
# Google:
nameserver 8.8.8.8
nameserver 8.8.4.4" >> /etc/resolv.dnsmasq.conf'

if [ -e "/etc/resolver/default" ] ; then
  printf "> You already have a resolver set for when you are offline..\n> So this all works proerly I'm going to delete and recreate it..\n"
  sudo rm /etc/resolver/default
fi

printf "> Making local domains resolve when your disconnected from net..\n"
sudo mkdir -p /etc/resolver
sudo sh -c 'echo "nameserver 127.0.0.1
domain ." >> /etc/resolver/default'

printf "> Setting network interfaces to use 127.0.0.1 for DNS lookups, this will error on nonexistent interfaces..\n"
sudo networksetup -setdnsservers AirPort 127.0.0.1
sudo networksetup -setdnsservers Ethernet 127.0.0.1
sudo networksetup -setdnsservers 'Thunderbolt Ethernet' 127.0.0.1
sudo networksetup -setdnsservers Wi-Fi 127.0.0.1

printf "> Setting hostname to $hname..\n"
sudo scutil --set HostName $hname

# Start dnsmasq
printf "> Copying dnsmasq launch daemon into place..\n"
sudo cp $(brew --prefix dnsmasq)/homebrew.mxcl.dnsmasq.plist /Library/LaunchDaemons
printf "> Starting dnsmasq..\n"
sudo launchctl load -w /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist

printf "> Installing nginx..\n"
brew install pcre geoip
brew install https://gist.github.com/BrianGilbert/5908548/raw/4e36bff848c4552062861ff66e30b841605ad4e0/nginx.rb --with-realip --with-gzip --with-stub --with-webdav --with-flv --with-mp4 --with-geoip --with-upload --with-ssl
printf "> Configuring nginx..\n"
if [ -e "/usr/local/etc/nginx/nginx.conf" ] ; then
mv /usr/local/etc/nginx/nginx.conf /usr/local/etc/nginx/nginx.conf.bak
fi
curl https://gist.github.com/BrianGilbert/5908352/raw/26e5943ec52c1d43c867fc16c4960e291b17f7d2/nginx.conf > /usr/local/etc/nginx/nginx.conf
sed -i '' 's/\[username\]/'$username'/' /usr/local/etc/nginx/nginx.conf
sudo mkdir -p /var/log/nginx
sudo mkdir -p /var/lib/nginx

printf "> Installing mariadb..\n"
brew install cmake
brew install mariadb
unset TMPDIR
printf "> Configuring mariadb..\n"
mysql_install_db --user=$username --basedir="$(brew --prefix mariadb)" --datadir=/usr/local/var/mysql --tmpdir=/tmp
curl https://gist.github.com/BrianGilbert/6207328/raw/10e298624ede46e361359b78a1020c82ddb8b943/my-drupal.cnf > /usr/local/etc/my-drupal.cnf
sudo ln -s /usr/local/etc/my-drupal.cnf /etc/my.cnf

printf "> Installing php..\n"
brew install php53 --without-apache --with-mysql --with-fpm --with-imap
brew install php53-xhprof
brew install php53-xdebug
brew install php53-uploadprogress

printf "> Configuring php..\n"
sed -i '' '/timezone =/ a\
date.timezone = Australia/Melbourne\
' /usr/local/etc/php/5.3/php.ini
sed -i '' 's/post_max_size = .*/post_max_size = '50M'/' /usr/local/etc/php/5.3/php.ini
sed -i '' 's/upload_max_filesize = .*/upload_max_filesize = '10M'/' /usr/local/etc/php/5.3/php.ini
sed -i '' 's/max_execution_time = .*/max_execution_time = '90'/' /usr/local/etc/php/5.3/php.ini
sed -i '' 's/memory_limit = .*/memory_limit = '512M'/' /usr/local/etc/php/5.3/php.ini
sed -i '' 's/pdo_mysql.default_socket=.*/pdo_mysql.default_socket= \/tmp\/mysql.sock/' /usr/local/etc/php/5.3/php.ini
sed -i '' '/pid = run/ a\
pid = /usr/local/var/run/php-fpm.pid\
' /usr/local/etc/php/5.3/php-fpm.conf

sudo ln -s /usr/local/etc/php/5.3/php.ini /etc/php.ini
sudo ln -s $(brew --prefix josegonzalez/php/php53)/var/log/php-fpm.log /var/log/nginx/php-fpm.log

#Solr
if [ $solr != n -o $solr != N ] ; then
printf "> Installing solr..\n"
brew install solr
mkdir -p ~/Library/LaunchAgents
printf "> Downloading solr launch daemon..\n"
curl https://gist.github.com/BrianGilbert/6208150/raw/dfe9d698aee2cdbe9eeae88437c5ec844774bdb4/com.apache.solr.plist > ~/Library/LaunchAgents/com.apache.solr.plist
sed -i '' 's/\[username\]/'$username'/' ~/Library/LaunchAgents/com.apache.solr.plist
fi

printf "> Setting up launch daemons..\n"
sudo cp $(brew --prefix nginx)/homebrew.mxcl.nginx.plist /Library/LaunchDaemons/
sudo chown root:wheel /Library/LaunchDaemons/homebrew.mxcl.nginx.plist

mkdir -p ~/Library/LaunchAgents
cp $(brew --prefix mariadb)/homebrew.mxcl.mariadb.plist ~/Library/LaunchAgents/
cp $(brew --prefix josegonzalez/php/php53)/homebrew-php.josegonzalez.php53.plist ~/Library/LaunchAgents/

printf "> Launching daemons now..\n"
sudo launchctl load -w /Library/LaunchDaemons/homebrew.mxcl.nginx.plist
launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.mariadb.plist
launchctl load -w ~/Library/LaunchAgents/homebrew-php.josegonzalez.php53.plist
if [ $solrboot != n -o $solrboot != N ] ; then
  launchctl load -w ~/Library/LaunchAgents/com.apache.solr.plist
fi

printf "> Finishing mariadb setup..\n"
echo "########
# Enter the following when prompted..
#
# Current password: [hit enter]
# Set root password?: [Y/n] y
# New password: [make it easy, eg. mysql]
# Remove anonymous users? [Y/n] y
# Disallow root login remotely? [Y/n] y
# Remove test database and access to it? [Y/n] y
# Reload privilege tables now? [Y/n] y
########" #remove this echo when expects block below is fixed.

sudo PATH="/usr/local/bin:/usr/local/sbin:$PATH" $(brew --prefix mariadb)/bin/mysql_secure_installation #remove this line when expects block below is fixed.
# This expect block throws error
# /usr/local/opt/mariadb/bin/mysql_secure_installation: line 379: find_mysql_client: command not found
# Any help greatly appreciated..
#
# expect -c "
#   spawn sudo PATH="/usr/local/bin:/usr/local/sbin:$PATH" /usr/local/opt/mariadb/bin/mysql_secure_installation
#   expect \"Enter current password for root (enter for none):\"
#   send \"\r\"
#   expect \"Set root password?: \\\\\\[Y/n\\\\\\]\"
#   send \"y\r\"
#   expect \"New password:\"
#   send \"mysql\r\"
#   expect \"Re-enter new password:\"
#   send \"mysql\r\"
#   expect \"Remove anonymous users? \\\\\\[Y/n\\\\\\]\"
#   send \"y\r\"
#   expect \"Disallow root login remotely? \\\\\\[Y/n\\\\\\]\"
#   send \"y\r\"
#   expect \"Remove test database and access to it? \\\\\\[Y/n\\\\\\]\"
#   send \"y\r\"
#   expect \"Reload privilege tables now? \\\\\\[Y/n\\\\\\]\"
#   send \"y\r\"
#   expect eof"

printf "> Doing some setup ready for Aegir install..\n"
sudo mkdir -p /var/aegir
sudo chown $username /var/aegir
sudo chgrp staff /var/aegir
sudo dscl . append /Groups/_www GroupMembership $username
echo "$username ALL=NOPASSWD: /usr/local/bin/nginx" | sudo tee -a  /etc/sudoers
ln -s /var/aegir/config/nginx.conf /usr/local/etc/nginx/aegir.conf

printf "> Adding aegir.conf include to ngix.conf..\n"
ed -s /usr/local/etc/nginx/nginx.conf <<< $'g/#aegir/s!!include /usr/local/etc/nginx/aegir.conf;!\nw'

printf "> Aegir time..\n"
printf "> Downloading provision..\n"
DRUSH='drush --php=/usr/local/bin/php'
$DRUSH dl --destination=/users/$username/.drush provision-6.x-2.x
printf "> Clearing drush caches..\n"
$DRUSH cache-clear drush
printf "> Installing hostmaster..\n"

$DRUSH hostmaster-install --aegir_root='/var/aegir' --root='/var/aegir/hostmaster-6.x-2.x-dev' --http_service_type=nginx --aegir_host=aegir.ld  --client_email=$email aegir.ld #remove this line when/if expects block below is enabled again.

# This expect block works but the previous expect block doesn't so can't use this yet.
# expect -c "
#   drush hostmaster-install --aegir_root='/var/aegir' --root='/var/aegir/hostmaster-6.x-2.x-dev' --http_service_type=nginx --aegir_host=aegir.ld  --client_email=$email aegir.ld
#   expect \") password:\"
#   send \"mysql\r\"
#   expect \"Do you really want to proceed with the install (y/n):\"
#   send \"y\r\"
#   expect eof"

printf "> Symlinking platforms to ~/Sites/aegir..\n"
mkdir -p /Users/$username/Sites/Aegir
rmdir /var/aegir/platforms
ln -s /Users/$username/Sites/Aegir /var/aegir/platforms

printf "> Saving some notes to ~/Desktop/YourAegirSetup.txt..\n"
sudo sh -c 'echo "Hi fellow Drupaler,

Here is some important information about your local Aegir setup.

The date.timezone value is set to Melbourne/Australia you may want
to change it to something that suits you better.

To change it type this in a terminal and search for Melbourne:
nano /usr/local/etc/php/5.3/php.ini

I have tried to set DNS for commonly named network interfaces check
all of your interfaces to ensure that the DNS server is set to:
127.0.0.1

New Aegir platforms go in ~/Sites/Aegir/

If you configured mail sending email you will also have received an
email with a one time login link for your Aegir site.

If you elected to setup ApacheSolr the default port has been changed
to match the port used by Barracuda [1].
You can access the Solr4 WebUI at: http://localhost:8099/solr/

When you set up search_api_solr you will need to copy the contents
of the 4.x version of the solr-conf files that come with the module
into each core you set up, eg.:
/usr/local/opt/solr/libexec/example/multicore/core0/conf

If you did not elect to load solr on boot you can run it by executing
the following in a terminal:
launchctl load ~/Library/LaunchAgents/com.apache.solr.plist
To stop it:
launchctl unload ~/Library/LaunchAgents/com.apache.solr.plist

After using this script please take the time to say thanks:
http://twitter.com/BrianGilbert_


1. https://drupal.org/project/barracuda
" >> ~/Desktop/YourAegirSetup.txt'

printf "> Attempting to email it to you as well..\n"
mail -s 'Your local Aegir setup' $email < ~/Desktop/YourAegirSetup.txt

printf "> The date.timezone value in /usr/local/etc/php/[version]/php.ini\n> Is set to Melbourne/Australia\n> You may want to change it to something that suits you better.\n"
# printf "The mysql root password is set to 'mysql' and login is only possible from localhost..\n"
printf "> Double check your network interfaces to ensure their DNS server is set to 127.0.0.1 as we only tried to set commonly named interfaces.\n"
printf "> Please say thanks @BrianGilbert_  http://twiter.com/BrianGilbert_\n"
printf "Finished..\n"
exit
