#!/bin/sh
# Written by Brian Gilbert @BrianGilbert_ https://github.com/BrianGilbert
# of Realityloop @Realityloop http://realitylop.com/
# I'm by no means a bash scripter, please submit pull requests/issues for improvements. :)
{
  # set volume so say text can be heard
  osascript -e "set Volume 5"

  curl --silent --head https://www.github.com/ | grep "20[0-9] Found|30[0-9] Found" > /dev/null
  if [[ $? -eq 1 ]] ; then
    printf "########\n# Online, continuing $(date +"%Y-%m-%d %H:%M:%S")\n"
  else
    printf "########\n# This script needs Internet access and you are offline, exiting\n########\n"
    say " you need to be online to run this script, exiting"
    exit
  fi

  # Set some variables for username installing aegir and the OS X version
  USERNAME=${USER-$LOGNAME} #`ps -o user= $(ps -o ppid= $PPID)`
  DRUSH='drush --php=/usr/local/bin/php'
  OSX=`sw_vers -productVersion | cut -c 1-4`

  # Make sure that the script wasn't run as root.
  if [ ${USERNAME} = "root" ] ; then
    printf "########\n# This script should not be run as sudo or root. exiting.\n########\n"
    say "This script should not be run as sudo or root. exiting."
    exit
  else
    #fresh installations of mac osx does not have /usr/local, so we need to create it first in case it's not there.
    printf "########\n# Checking /usr/local exists..\n"
    if [ ! -d '/usr/local' ] ; then
      printf "# It doesn't so I'm creating it..\n"
      say "you may need to enter your password"
      sudo mkdir -p /usr/local
    fi
    ls -l /usr/local| awk '{print $3}'|grep root > /dev/null
    if [[ $? -eq 0 ]] ; then
      printf "# Setting it's permissions correctly..\n########\n"
      sudo chown -R ${USERNAME}:admin /usr/local
      chmod 775 /usr/local
    fi
  fi

  printf "########
# This script is designed to be run by the primary account
# it has not been tested on a multi user setup.
########
# You will need the following information during this script:
# -a gmail account that is configured to allow remote smtp access
# -the password for the gmail account address
# -an email address to receive notifications from aegir
# -attention to what is being requested via the script
########
# You cannot use this script if you have macports installed
# so we will uninstall it automatically
########
# OS X's inbuilt apache uses port 80 if it's running we'll disable
# it for you during install so that nginx can run on port 80.
########
# Logging install process to file on desktop in case anything
# goes wrong during install, No passwords are logged..
########\n"

  port > /dev/null 2&>1
  if [[ $? -eq 127 ]] ; then
    printf "########\n# macports isn't installed continuing..\n"
  else
    printf "########\n# Attempting to uninstall macports..\nn"
    say "you may need to enter your password"
    sudo port -fp uninstall installed > /dev/null 2&>1
    sudo rm -rf \
        /opt/local \
        /Applications/DarwinPorts \
        /Applications/MacPorts \
        /Library/LaunchDaemons/org.macports.* \
        /Library/Receipts/DarwinPorts*.pkg \
        /Library/Receipts/MacPorts*.pkg \
        /Library/StartupItems/DarwinPortsStartup \
        /Library/Tcl/darwinports1.0 \
        /Library/Tcl/macports1.0 \
        ~/.macports > /dev/null 2&>1
  fi

  ps aux|grep "httpd"|grep -v grep > /dev/null
  if [[ $? -eq 1 ]] ; then
    printf "########\n# Apache isn't active, continuing..\n########\n"
  else
    printf "########\n# Disabling apache now..\n########\n"
    say "you may need to enter your password"
    sudo launchctl unload -w /System/Library/LaunchDaemons/org.apache.httpd.plist
  fi

  printf "\n########\n# Checking OS version..\n########\n"
  if [ ${OSX} = 10.9 ] ; then
    printf "# Your using $OSX, so let's go!\n########\n"
  else
    printf "# ${OSX} isn't a supported version for this script\n# Update to 10.9+ and rerun the script, exiting.\n########\n"
      exit
  fi

  # Check Aegir isn't already installed.
  if [ -e "/var/aegir/.osxaegir" ] ; then
    printf "# You already have aegir installed..\n########\n"
    say "You already have a gir installed.."
    #exit # Remove this line when uninstall block below is fixed.
    # Possibly I'll allow reinstallations in the future..
    #
    printf "# Should I remove it? The option to re-install will be given after this. [Y/n]\n########\n"
    say "input required"
    read -n1 CLEAN

    if [[ ${CLEAN} =~ ^(y|Y)$ ]]; then
      printf "# You entered Y\n########\n"
      printf "# There is no turning back..\n# This will uninstall aegir and all related homebrew components, are you sure? [Y/n]\n########\n"
      say "There is no turning back.. This will uninstall a gir and all related homebrew components including any existing databases, are you sure?"
      read -n1 FORSURE
      if [[ ${FORSURE} =~ ^(y|Y)$ ]]; then
        printf "\n########\n# You entered Y\n"
        printf "\n########\n# Don't say I didn't warn you, cleaning everything..\n########\n"
        say "Don't say I didn't warn you, removing components.."

        printf "# Stopping and deleting any services that are already installed..\n########\n"
        if [ -e "/Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist" ] ; then
          sudo launchctl unload -w /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist
          sudo rm /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist
        fi

        if [ -e "/Library/LaunchDaemons/homebrew.mxcl.nginx.plist" ] ; then
          sudo launchctl unload -w /Library/LaunchDaemons/homebrew.mxcl.nginx.plist
          sudo rm /Library/LaunchDaemons/homebrew.mxcl.nginx.plist
        fi

        if [ -e "~/Library/LaunchAgents/homebrew.mxcl.mariadb.plist" ] ; then
          launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.mariadb.plist
          kill $(ps aux | grep 'mysqld' | awk '{print $2}')
        fi

        if [ -e "~/Library/LaunchAgents/homebrew.mxcl.php53.plist" ] ; then
          launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php53.plist
          rm ~/Library/LaunchAgents/homebrew.mxcl.php53.plist
        fi

        if [ -e "~/Library/LaunchAgents/homebrew.mxcl.php54.plist" ] ; then
          launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php54.plist
          rm ~/Library/LaunchAgents/homebrew.mxcl.php54.plist
        fi

        if [ -e "~/Library/LaunchAgents/homebrew.mxcl.php55.plist" ] ; then
          launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php55.plist
          rm ~/Library/LaunchAgents/homebrew.mxcl.php55.plist
        fi

        if [ -e "~/Library/LaunchAgents/org.aegir.hosting.queued.plist" ] ; then
          launchctl unload -w ~/Library/LaunchAgents/org.aegir.hosting.queued.plist
          rm ~/Library/LaunchAgents/org.aegir.hosting.queued.plist
        fi

        printf "########\n# Uninstalling related brews..\n########\n"
        brew uninstall php53-geoip
        brew uninstall php53-imagick
        brew uninstall php53-mcrypt
        brew uninstall php53-uploadprogress
        brew uninstall php53-xdebug
        brew uninstall php53-xhprof
        brew uninstall php53
        sudo rm /var/log/nginx/php53-fpm.log
        rm /usr/local/bin/go53

        brew uninstall php54-geoip
        brew uninstall php54-imagick
        brew uninstall php54-mcrypt
        brew uninstall php54-uploadprogress
        brew uninstall php54-xdebug
        brew uninstall php54-xhprof
        brew uninstall php54
        sudo rm /var/log/nginx/php54-fpm.log
        rm /usr/local/bin/go54

        brew uninstall php55-geoip
        brew uninstall php55-imagick
        brew uninstall php55-mcrypt
        brew uninstall php55-uploadprogress
        brew uninstall php55-xdebug
        brew uninstall php55-xhprof
        brew uninstall php55
        sudo rm /var/log/nginx/php55-fpm.log
        rm /usr/local/bin/go55

        rm -rf /usr/local/etc/php

        brew uninstall php-code-sniffer
        brew uninstall drupal-code-sniffer
        brew uninstall phpunit

        brew uninstall re2c
        brew uninstall flex
        brew uninstall bison27
        brew uninstall libevent
        brew uninstall openssl
        brew uninstall solr

        sudo rm $(brew --prefix nginx)/logs/error.log
        rm -rf /usr/local/etc/nginx
        rm -rf /usr/local/var/run/nginx
        sudo rm /var/log/nginx/error.log
        brew uninstall nginx

        brew uninstall pcre geoip
        brew uninstall dnsmasq
        sudo rm /etc/resolv.dnsmasq.conf
        rm -rf /usr/local/etc/dnsmasq.conf
        sudo rm /etc/resolver/default
        sudo networksetup -setdnsservers AirPort empty
  			sudo networksetup -setdnsservers Ethernet empty
  			sudo networksetup -setdnsservers 'Thunderbolt Ethernet' empty
  			sudo networksetup -setdnsservers Wi-Fi empty

        printf "# Removing previous drush installation, this may error..\n########\n"
        brew uninstall drush
        brew uninstall gzip
        brew uninstall wget
        printf "# Removing related configurations..\n########\n"
        sudo launchctl unload /System/Library/LaunchDaemons/org.postfix.master.plist
        sudo rm /etc/postfix/sasl_passwd
        sudo rm /etc/postfix/main.cf
        sudo cp /etc/postfix/main.cf.orig /etc/postfix/main.cf
        rm ~/.forward

        rm ~/Library/LaunchAgents/homebrew.mxcl.mariadb.plist
  			brew uninstall mariadb
        rm /usr/local/etc/my-drupal.cnf
        rm /usr/local/etc/my.cnf
        rm -rf /usr/local/etc/my.cnf.d
        sudo rm /etc/my.cnf
        rm -rf /usr/local/var/mysql

        brew uninstall autoconf
        brew uninstall cmake
        brew uninstall curl
        brew uninstall freetype
        brew uninstall gettext
        brew uninstall gmp
        brew uninstall gzip
        brew uninstall imagemagick
        brew uninstall imap-uw
        brew uninstall jpeg
        brew uninstall libpng
        brew uninstall libtool
        brew uninstall mcrypt
        brew uninstall pkg-config
        brew uninstall unixodbc
        brew uninstall zlib
        brew uninstall apple-gcc42

        rm ~/Desktop/YourAegirSetup.txt

        printf "# Removing Aegir folder..\n########\n"
        sudo rm -rf /var/aegir

        say "input required"
        printf "# would you now like to re-install Aegir? [Y/n]\n########\n"
        read -n1 REINSTALL
        if [[ ${REINSTALL} =~ ^(y|Y)$ ]]; then
          printf "\n########\n# You entered Y\n########\n"
        else
          printf "\n########\n# You entered N\n########\n"
          exit
        fi

      else
        printf "# Exiting..\n########\n"
        exit
      fi
    # else
    #   printf "# Should I attempt an upgrade? [Y/n]\n########\n"
    #   say "Should I remove it and do, a clean install?"
    #   read UPGRADE
    #   if [[ $UPGRADE =~ ^(y|Y)$ ]]; then
    #     $DRUSH dl --destination=/var/aegir/.drush provision-6.x-2.0
    #     $DRUSH cache-clear drush
    #     OLD_AEGIR_DIR=/var/aegir/hostmaster/000
    #     AEGIR_VERSION=6.x-2.0
    #     AEGIR_DOMAIN=aegir.ld
    #     cd $OLD_AEGIR_DIR
    #     drush hostmaster-migrate $AEGIR_DOMAIN $HOME/hostmaster-$AEGIR_VERSION
    #     say "Upgrade isn't implemented yet"
    #     exit
    #   else
    #     printf "# Exiting..\n########\n"
    #     say "Exiting."
    #     exit
    #   fi
    fi
  fi

  printf "\n########\n# Checking if Homebrew is installed..\n########\n"
  if type "brew" > /dev/null 2>&1; then
    printf "\n########\n# Affirmative! Lets make sure everything is up to date..\n# Just so you know, this may throw a few warnings..\n########\n"
    say "Making sure homebrew is up to date, you may see some errors in the output, thats ok."
    export PATH=/usr/local/bin:/usr/local/sbin:${PATH}
    brew prune
    brew update
    brew doctor
    if [[ $? -eq 0 ]] ; then
      printf "########\n# Homebrew in order, continuing\n########"
    else
      printf "########\n# Homebrew needs some work, exiting\n########"
      exit
    fi
  else
    printf "# Nope! Installing Homebrew now..\n########\n"
    say "Installing homebrew now, you'll need to hit return when prompted"
    ruby -e "$(curl -fsSL https://raw.github.com/mxcl/homebrew/go/install)"
    echo 'export PATH=/usr/local/bin:/usr/local/sbin:$PATH' >> ~/.bash_profile
    echo 'export PATH=/usr/local/bin:/usr/local/sbin:$PATH' >> ~/.zshrc
    source ~/.bash_profile
  fi

  printf "\n########\n# Doing some setup ready for Aegir install..\n########"
  sudo mkdir -p /var/aegir
  sudo chown ${USERNAME} /var/aegir
  sudo chgrp staff /var/aegir
  echo "$(date +"%Y-%m-%d %H:%M:%S")" > /var/aegir/.osxaegir
  sudo dscl . append /Groups/_www GroupMembership ${USERNAME}

  echo "
########
# I can install multiple versions of PHP; 5.3, 5.4 and/or 5.5.
# Let me know which versions you'd like installed.
# Set up PHP 5.3 [Y/n]:
########"
  say "input required"
  read -n1 PHP53

  if [[ ${PHP53} =~ ^(y|Y)$ ]]; then
    echo "
########
# Make PHP 5.3 the default [Y/n]:
########"
    say "input required"
    read -n1 PHP53DEF
  fi

  echo "
########
# Set up PHP 5.4 [Y/n]:
########"
  say "input required"
  read -n1 PHP54

  if [[ ! ${PHP53DEF} =~ ^(y|Y)$ ]]; then
    if [[ ${PHP54} =~ ^(y|Y)$ ]]; then
      echo "
########
# Make PHP 5.4 the default [Y/n]:
########"
      say "input required"
      read -n1 PHP54DEF
    fi
  fi

  echo "
########
# Set up PHP 5.5 [Y/n]:
########"
  say "input required"
  read -n1 PHP55

  if [[ ${PHP53DEF} =~ ^(y|Y)$ || ${PHP54DEF} =~ ^(y|Y)$ ]]; then
    echo""
  else
    echo "
########
# Make PHP 5.5 the default [Y/n]:
########"
    say "input required"
    read -n1 PHP55DEF
  fi

  if [[ ! ${PHP53} =~ ^(y|Y)$ && ! ${PHP54} =~ ^(y|Y)$ && ! ${PHP55} =~ ^(y|Y)$ ]]; then
    echo "
########
# You didn't select any version of PHP?!? So I'm installing PHP5.5
########"
  PHP55="Y"
  PHP55DEF="Y"
  fi

echo "
########
# I can also setup ApacheSolr which is best used in conjunction with:
# https://drupal.org/project/search_api_solr
# Set up solr [Y/n]:
########"
  say "input required"
  read -n1 SOLR

  if [[ ${SOLR} =~ ^(y|Y)$ ]]; then
    printf "# You entered Y\n########\n"
    echo "
########
# Do you want solr to run automatically on boot [Y/n]:
########"
    say "input required"
    read -n1 SOLRBOOT
    if [[ ${SOLRBOOT} =~ ^(y|Y)$ ]]; then
      printf "# You entered Y\n########\n"
    else
      printf "# You entered N\n########\n"
    fi
  fi

  echo "
########
# What address should aegirs email notifications get sent to? [enter your email address]:
########"
  say "This is the email that notifications from a gir will be sent to"
  read EMAIL

  echo "
########
# I need to set up postfix so you receive emails from Aegir, if you don't
# installation will surely fail !!!
#
# !!! This has only been tested with gmail accounts !!!
#
# Do you have a gmail account you can use? [Y/n]:
########"
  say "Do you have a gee mail address you can use to relay the messages?"
  read -n1 GMAIL
  if [[ ${GMAIL} =~ ^(y|Y)$ ]]; then
    printf "\n########\n# You entered Y\n########\n"
    printf "# OK, I'll attempt to set up postfix..\n"
    echo "########
# Whats the full gmail address? (eg. aegir@gmail.com):
########"
  say "type your gee mail address in now"
    read GMAILADDRESS
    echo "
########
# What is the account password?
########"
  say "type your gee mail password in now"
    read GMAILPASS

    #setup mail sending
    printf "\n########\n# No time like the present, lets set up postfix now..\n########\n"
    say "You may be prompted for your password"
    sudo launchctl unload /System/Library/LaunchDaemons/org.postfix.master.plist > /dev/null 2&>1
    echo "smtp.gmail.com:587 ${GMAILADDRESS}:${GMAILPASS}"  | sudo tee -a  /etc/postfix/sasl_passwd > /dev/null 2&>1
    sudo cp /etc/postfix/main.cf /etc/postfix/main.cf.orig
    echo "
myhostname = aegir.ld

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
tls_random_source=dev:/dev/urandom" | sudo tee -a  /etc/postfix/main.cf > /dev/null 2&>1
    echo  "${EMAIL}" >> ~/.forward
    sudo postmap /etc/postfix/sasl_passwd
    sudo launchctl load -w /System/Library/LaunchDaemons/org.postfix.master.plist
  else
    printf "\n# Mail sending from aegir won't actually work until you configure postfix properly..\n"
    printf "\n# See: http://realityloop.com/blog/2011/06/05/os-x-ditching-mamp-pro-part-2-gmail-email-relay\n"
    say "Mail sending won't actually work until you configure postfix properly"
  fi

  # Tap required kegs
  printf "\n########\n# Now we'll tap some extra kegs we need..\n########\n"
  brew tap homebrew/versions
  brew tap homebrew/dupes
  brew tap josegonzalez/homebrew-php
  brew update
  brew doctor

  # Install required formula's
  printf "# Installing required brew formulae..\n########\n"
  printf "# Installing gcc..\n########\n"
  brew install apple-gcc42
  printf "\n########\n# Installing wget..\n########\n"
  brew install wget
  printf "\n########\n# Installing gzip..\n########\n"
  brew install gzip
  printf "\n########\n# Installing libpng..\n########\n"
  brew install libpng
  printf "\n########\n# Installing drush..\n########\n"
  # Uninstall drush if it was previously installed via homebrew
  brew uninstall drush > /dev/null 2&>1
  # printf "# Installing composer..\n########\n"  # this needs to be moved after phph installation
  brew install drush
  printf "\n########\n# Installing dnsmasq..\n########\n"
  brew install dnsmasq
  printf "\n########\n# Configuring dnsmasq..\n########\n"
  mkdir -p /usr/local/etc

  # Configure dnsmasq
  printf "########\n# Setting up wildcard DNS so that domains ending in dot ld will resolve to your local machine\n"
  if [ -e "/usr/local/etc/dnsmasq.conf" ] ; then
    printf "########\n# You already have a dnsmasq.conf file..\n# So this all works proerly I'm going to delete and recreate it..\n########\n"
    rm /usr/local/etc/dnsmasq.conf
  fi

  printf "# Setting dnsmasq config..\n########\n"
  cp $(brew --prefix dnsmasq)/dnsmasq.conf.example /usr/local/etc/dnsmasq.conf
  echo '# Edited by MEMPAE script' | cat - /usr/local/etc/dnsmasq.conf > temp && mv temp /usr/local/etc/dnsmasq.conf
  echo "resolv-file=/etc/resolv.dnsmasq.conf" >> /usr/local/etc/dnsmasq.conf
  echo "address=/.ld/127.0.0.1" >> /usr/local/etc/dnsmasq.conf
  echo "listen-address=127.0.0.1" >> /usr/local/etc/dnsmasq.conf
  echo "addn-hosts=/usr/local/etc/dnsmasq.hosts" >> /usr/local/etc/dnsmasq.conf
  touch /usr/local/etc/dnsmasq.hosts

  if [ -e "/etc/resolv.dnsmasq.conf" ] ; then
    printf "# You already have a resolv.conf set..\n# So this all works properly I'm going to delete and recreate it..\n########\n"
    say "You may be prompted for your password"
    sudo rm /etc/resolv.dnsmasq.conf
  fi

  printf "# Setting OpenDNS and Google DNS servers as fallbacks..\n########\n"
  say "You may need to enter your password now"
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
    printf "# You already have a resolver set for when you are offline..\n# So this all works properly I'm going to delete and recreate it..\n########\n"
    say "You may be prompted for your password"
    sudo rm /etc/resolver/default
  fi

  printf "########\n# Making local domains resolve when your disconnected from net..\n########\n"
  sudo mkdir -p /etc/resolver
  sudo sh -c 'echo "nameserver 127.0.0.1
  domain ." >> /etc/resolver/default'

  printf "# Setting known network interfaces to use 127.0.0.1 for DNS lookups,this may throw errors, thats ok...\n########\n"
  sudo networksetup -setdnsservers AirPort 127.0.0.1
  sudo networksetup -setdnsservers Ethernet 127.0.0.1
  sudo networksetup -setdnsservers 'Thunderbolt Ethernet' 127.0.0.1
  sudo networksetup -setdnsservers Wi-Fi 127.0.0.1

  echo "
########
# Open your network settings now and confirm the DNS for
# your active device is set to 127.0.0.1, or else things
# will not work properly later in the script.
########"
  say "Open your network settings to confirm DNS for your active network device is set to 127.0.0.1, or else things will not work properly later in the script"
  printf "# Setting hostname to aegir.ld\n########\n"
  sudo scutil --set HostName aegir.ld

  # Start dnsmasq
  printf "# Copying dnsmasq launch daemon into place..\n########\n"
  sudo cp $(brew --prefix dnsmasq)/homebrew.mxcl.dnsmasq.plist /Library/LaunchDaemons
  printf "# Starting dnsmasq..\n########\n"
  sudo launchctl load -w /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist

  printf "\n########\n# Installing nginx..\n########\n"
  brew install pcre geoip
  brew install nginx --with-debug --with-flv --with-geoip --with-http_dav_module --with-mp4 --with-spdy --with-ssl --with-upload-progress
  printf "\n########\n# Configuring nginx..\n########\n"
  if [ -e "/usr/local/etc/nginx/nginx.conf" ] ; then
  mv /usr/local/etc/nginx/nginx.conf /usr/local/etc/nginx/nginx.conf.bak
  fi
  curl https://gist.githubusercontent.com/BrianGilbert/5908352/raw/2b6f9094348af7b8d64c3582a0e6e67164bd0168/nginx.conf > /usr/local/etc/nginx/nginx.conf
  sed -i '' 's/\[username\]/'${USERNAME}'/' /usr/local/etc/nginx/nginx.conf

  say "You may be prompted for your password"
  sudo mkdir -p $(brew --prefix nginx)/logs
  sudo mkdir -p /var/log/nginx
  sudo ln -s $(brew --prefix nginx)/logs/error.log /var/log/nginx/error.log
  sudo mkdir -p /var/lib/nginx

  printf "\n########\n# Installing mariadb..\n########\n"
  brew install cmake
  brew install mariadb
  unset TMPDIR
  printf "\n########\n# Configuring mariadb..\n########\n"
  mysql_install_db --user=${USERNAME} --basedir="$(brew --prefix mariadb)" --datadir=/usr/local/var/mysql --tmpdir=/tmp
  curl https://gist.githubusercontent.com/BrianGilbert/6207328/raw/10e298624ede46e361359b78a1020c82ddb8b943/my-drupal.cnf > /usr/local/etc/my-drupal.cnf
  say "You may be prompted for your password"
  sudo ln -s /usr/local/etc/my-drupal.cnf /etc/my.cnf

if [[ ${PHP55} =~ ^(y|Y)$ ]]; then
  printf "\n########\n# Installing php55..\n########\n"
  brew install php55 --without-apache --with-fpm --with-gmp --with-imap --with-mysql --with-homebrew-curl --with-homebrew-libxslt --with-homebrew-openssl
  brew install php55-geoip
  brew install php55-imagick
  brew install php55-mcrypt
  brew install php55-uploadprogress
  brew install php55-xdebug
  brew install php55-xhprof

  # Make sure LaunchAgents directory exists
  mkdir -p ~/Library/LaunchAgents

  printf "\n########\n# Configuring php55..\n########\n"
  sed -i '' '/timezone =/ a\
  date.timezone = Australia/Melbourne\
  ' /usr/local/etc/php/5.5/php.ini
  sed -i '' 's/post_max_size = .*/post_max_size = '50M'/' /usr/local/etc/php/5.5/php.ini
  sed -i '' 's/upload_max_filesize = .*/upload_max_filesize = '10M'/' /usr/local/etc/php/5.5/php.ini
  sed -i '' 's/max_execution_time = .*/max_execution_time = '90'/' /usr/local/etc/php/5.5/php.ini
  sed -i '' 's/memory_limit = .*/memory_limit = '512M'/' /usr/local/etc/php/5.5/php.ini
  sed -i '' 's/pdo_mysql.default_socket=.*/pdo_mysql.default_socket= \/tmp\/mysql.sock/' /usr/local/etc/php/5.5/php.ini
  sed -i '' '/pid = run/ a\
  pid = /usr/local/var/run/php-fpm.pid\
  ' /usr/local/etc/php/5.5/php-fpm.conf

  # Additions for xdebug to work with PHPStorm
  echo "xdebug.max_nesting_level = 200

xdebug.profiler_enable = 1
xdebug.profiler_enable_trigger = 1
xdebug.profiler_output_name = xdebug-profile-cachegrind.out-%H-%R
xdebug.profiler_output_dir = /tmp/xdebug/

xdebug.remote_autostart = 0
xdebug.remote_enable=1
xdebug.remote_connect_back = 1
xdebug.remote_port = 9001
xdebug.remote_host = localhost

xdebug.var_display_max_children = 128
xdebug.var_display_max_data = 2048
xdebug.var_display_max_depth = 32" >> /usr/local/etc/php/5.5/conf.d/ext-xdebug.ini

  say "You may be prompted for your password"
  sudo ln -s $(brew --prefix josegonzalez/php/php55)/var/log/php-fpm.log /var/log/nginx/php55-fpm.log

  cp $(brew --prefix josegonzalez/php/php55)/homebrew.mxcl.php55.plist ~/Library/LaunchAgents/

  echo "#!/bin/sh
# Written by Brian Gilbert @BrianGilbert_ https://github.com/BrianGilbert
# of Realityloop @Realityloop http://realitylop.com/

# Remove old symlink for xhprof and create correct one for this version of php
rm /usr/local/opt/xhprof > /dev/null 2>&1
ln -s  $(brew --prefix php55-xhprof) /usr/local/opt/xhprof

# Stop php-fpm and start correct version
launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php53.plist > /dev/null 2>&1
launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php54.plist > /dev/null 2>&1
launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php55.plist > /dev/null 2>&1
launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.php55.plist

# Brew link correct php version
brew unlink php53
brew unlink php54
brew link php55

# Restart nginx
sudo /usr/local/bin/nginx -s reload" >> /usr/local/bin/go55
  chmod 755 /usr/local/bin/go55

  if [[ ! ${PHP55DEF} =~ ^(y|Y)$ ]]; then
    brew unlink php55
  fi
fi

if [[ ${PHP54} =~ ^(y|Y)$ ]]; then
  printf "\n########\n# Installing php54..\n########\n"
  brew install php54 --without-apache --with-fpm --with-gmp --with-imap --with-mysql --with-homebrew-curl --with-homebrew-libxslt --with-homebrew-openssl
  brew install php54-geoip
  brew install php54-imagick
  brew install php54-mcrypt
  brew install php54-uploadprogress
  brew install php54-xdebug
  brew install php54-xhprof

	printf "\n########\n# Configuring php54..\n########\n"
	sed -i '' '/timezone =/ a\
	date.timezone = Australia/Melbourne\
	' /usr/local/etc/php/5.4/php.ini
	sed -i '' 's/post_max_size = .*/post_max_size = '50M'/' /usr/local/etc/php/5.4/php.ini
	sed -i '' 's/upload_max_filesize = .*/upload_max_filesize = '10M'/' /usr/local/etc/php/5.4/php.ini
	sed -i '' 's/max_execution_time = .*/max_execution_time = '90'/' /usr/local/etc/php/5.4/php.ini
	sed -i '' 's/memory_limit = .*/memory_limit = '512M'/' /usr/local/etc/php/5.4/php.ini
	sed -i '' 's/pdo_mysql.default_socket=.*/pdo_mysql.default_socket= \/tmp\/mysql.sock/' /usr/local/etc/php/5.4/php.ini
	sed -i '' '/pid = run/ a\
	pid = /usr/local/var/run/php-fpm.pid\
	' /usr/local/etc/php/5.4/php-fpm.conf

  # Additions for xdebug to work with PHPStorm
  echo "xdebug.max_nesting_level = 200

xdebug.profiler_enable = 1
xdebug.profiler_enable_trigger = 1
xdebug.profiler_output_name = xdebug-profile-cachegrind.out-%H-%R
xdebug.profiler_output_dir = /tmp/xdebug/

xdebug.remote_autostart = 0
xdebug.remote_enable=1
xdebug.remote_connect_back = 1
xdebug.remote_port = 9001
xdebug.remote_host = localhost

xdebug.var_display_max_children = 128
xdebug.var_display_max_data = 2048
xdebug.var_display_max_depth = 32" >> /usr/local/etc/php/5.4/conf.d/ext-xdebug.ini

  say "You may be prompted for your password"
	sudo ln -s $(brew --prefix josegonzalez/php/php54)/var/log/php-fpm.log /var/log/nginx/php54-fpm.log

  mkdir -p ~/Library/LaunchAgents
  cp $(brew --prefix josegonzalez/php/php54)/homebrew.mxcl.php54.plist ~/Library/LaunchAgents/

  echo "#!/bin/sh
# Written by Brian Gilbert @BrianGilbert_ https://github.com/BrianGilbert
# of Realityloop @Realityloop http://realitylop.com/

# Remove old symlink for xhprof and create correct one for this version of php
rm /usr/local/opt/xhprof > /dev/null 2>&1
ln -s  $(brew --prefix php54-xhprof) /usr/local/opt/xhprof

# Stop php-fpm and start correct version
launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php53.plist > /dev/null 2>&1
launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php54.plist > /dev/null 2>&1
launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php55.plist > /dev/null 2>&1
launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.php54.plist

# Brew link correct php version
brew unlink php53
brew unlink php55
brew link php54

# Restart nginx
sudo /usr/local/bin/nginx -s reload" >> /usr/local/bin/go54
  chmod 755 /usr/local/bin/go54

  if [[ ! ${PHP54DEF} =~ ^(y|Y)$ ]]; then
    brew unlink php54
  fi
fi

if [[ ${PHP53} =~ ^(y|Y)$ ]]; then
  printf "\n########\n# Installing php53 prerequisites..\n########\n"
  brew install re2c
  brew install flex
  brew install bison27
  brew install libevent
  printf "\n########\n# Installing php53..\n########\n"
  brew install php53 --without-apache --with-fpm --with-gmp --with-imap --with-mysql --with-homebrew-curl --with-homebrew-libxslt --with-homebrew-openssl
  brew install php53-geoip
  brew install php53-imagick
  brew install php53-mcrypt
  brew install php53-uploadprogress
  brew install php53-xdebug
  brew install php53-xhprof

  printf "\n########\n# Configuring php53..\n########\n"
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

  # Additions for xdebug to work with PHPStorm
  echo "xdebug.max_nesting_level = 200

xdebug.profiler_enable = 1
xdebug.profiler_enable_trigger = 1
xdebug.profiler_output_name = xdebug-profile-cachegrind.out-%H-%R
xdebug.profiler_output_dir = /tmp/xdebug/

xdebug.remote_autostart = 0
xdebug.remote_enable=1
xdebug.remote_connect_back = 1
xdebug.remote_port = 9001
xdebug.remote_host = localhost

xdebug.var_display_max_children = 128
xdebug.var_display_max_data = 2048
xdebug.var_display_max_depth = 32" >> /usr/local/etc/php/5.3/conf.d/ext-xdebug.ini

  say "You may be prompted for your password"
  sudo ln -s $(brew --prefix josegonzalez/php/php53)/var/log/php-fpm.log /var/log/nginx/php53-fpm.log

  cp $(brew --prefix josegonzalez/php/php53)/homebrew.mxcl.php53.plist ~/Library/LaunchAgents/

  echo "#!/bin/sh
# Written by Brian Gilbert @BrianGilbert_ https://github.com/BrianGilbert
# of Realityloop @Realityloop http://realitylop.com/

# Remove old symlink for xhprof and create correct one for this version of php
rm /usr/local/opt/xhprof > /dev/null 2>&1
ln -s  $(brew --prefix php53-xhprof) /usr/local/opt/xhprof

# Stop php-fpm and start correct version
launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php53.plist > /dev/null 2>&1
launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php54.plist > /dev/null 2>&1
launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php55.plist > /dev/null 2>&1
launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.php53.plist

# Brew link correct php version
brew unlink php54
brew unlink php55
brew link php53

# Restart nginx
sudo /usr/local/bin/nginx -s reload" >> /usr/local/bin/go53
  chmod 755 /usr/local/bin/go53

  if [[ ! ${PHP53DEF} =~ ^(y|Y)$ ]]; then
    brew unlink php53
  fi
fi

  printf "\n########\n# Installing php code sniffer..\n########\n"
  brew install php-code-sniffer
  printf "\n########\n# Installing drupal code sniffer..\n########\n"
  brew install drupal-code-sniffer
  printf "\n########\n# Installing phpunit..\n########\n"
  brew install phpunit

  #Solr
  if [[ ${SOLR} =~ ^(y|Y)$ ]]; then
  printf "\n########\n# Installing solr..\n########\n"
  brew install solr
  mkdir -p ~/Library/LaunchAgents
  printf "\n########\n# Downloading solr launch daemon..\n########\n"
  curl https://gist.githubusercontent.com/BrianGilbert/6208150/raw/dfe9d698aee2cdbe9eeae88437c5ec844774bdb4/com.apache.solr.plist > ~/Library/LaunchAgents/com.apache.solr.plist
  sed -i '' 's/\[username\]/'${USERNAME}'/' ~/Library/LaunchAgents/com.apache.solr.plist
  fi

  printf "\n########\n# Setting up launch daemons..\n########\n"
  say "you may be prompted for your password"
  sudo cp $(brew --prefix nginx)/homebrew.mxcl.nginx.plist /Library/LaunchDaemons/
  sudo chown root:wheel /Library/LaunchDaemons/homebrew.mxcl.nginx.plist

  cp $(brew --prefix mariadb)/homebrew.mxcl.mariadb.plist ~/Library/LaunchAgents/


  printf "\n########\n# Launching daemons now..\n########\n"
  sudo launchctl load -w /Library/LaunchDaemons/homebrew.mxcl.nginx.plist
  launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.mariadb.plist
  if [[ ${PHP55DEF} =~ ^(y|Y)$ ]]; then
    launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php54.plist > /dev/null 2>&1
    launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php53.plist > /dev/null 2>&1
    launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.php55.plist
  fi
  if [[ ${PHP54DEF} =~ ^(y|Y)$ ]]; then
    launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php55.plist > /dev/null 2>&1
    launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php53.plist > /dev/null 2>&1
    launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.php54.plist
  fi
  if [[ ${PHP53DEF} =~ ^(y|Y)$ ]]; then
    launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php54.plist > /dev/null 2>&1
    launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php55.plist > /dev/null 2>&1
    launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.php53.plist
  fi
  if [[ ${SOLRBOOT} =~ ^(y|Y)$ ]]; then
    launchctl load -w ~/Library/LaunchAgents/com.apache.solr.plist
  fi

  printf "\n########\n# Finishing mariadb setup..\n########\n"
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
  say "Read the block above and enter responses as shown when propted"

  sudo PATH="/usr/local/bin:/usr/local/sbin:${PATH}" $(brew --prefix mariadb)/bin/mysql_secure_installation #remove this line when expects block below is fixed.
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

  echo "${USERNAME} ALL=NOPASSWD: /usr/local/bin/nginx" | sudo tee -a  /etc/sudoers
  ln -s /var/aegir/config/nginx.conf /usr/local/etc/nginx/aegir.conf

  printf "\n########\n# Adding aegir.conf include to ngix.conf..\n"
  ed -s /usr/local/etc/nginx/nginx.conf <<< $'g/#aegir/s!!include /usr/local/etc/nginx/aegir.conf;!\nw'

  printf "# Aegir time..\n########\n"
  printf "# Downloading provision..\n########\n"
  if [[ ${AEGIR7X} =~ ^(y|Y)$ ]]; then
    ${DRUSH} dl --destination=/Users/${USERNAME}/.drush provision-7.x-3.x
  else
    ${DRUSH} dl --destination=/Users/${USERNAME}/.drush provision-6.x-2.0
  fi
  printf "\n########\n# Clearing drush caches..\n########\n"
  ${DRUSH} cache-clear drush
  printf "\n########\n# Installing hostmaster..\n########\n"

  say "type the DB password you entered for my SQL earlier"
  if [[ ${AEGIR7X} =~ ^(y|Y)$ ]]; then
    ${DRUSH} hostmaster-install --aegir_root='/var/aegir' --root='/var/aegir/hostmaster-7.x-3.x' --http_service_type=nginx --aegir_host=aegir.ld  --client_email=${EMAIL} aegir.ld #remove this line when/if expects block below is enabled again.
  else
    ${DRUSH} hostmaster-install --aegir_root='/var/aegir' --root='/var/aegir/hostmaster-6.x-2.0' --http_service_type=nginx --aegir_host=aegir.ld  --client_email=${EMAIL} aegir.ld #remove this line when/if expects block below is enabled again.
  fi

  # This expect block works but the previous expect block doesn't so can't use this yet.
  # expect -c "
  #   drush hostmaster-install --aegir_root='/var/aegir' --root='/var/aegir/hostmaster-6.x-2.x-dev' --http_service_type=nginx --aegir_host=aegir.ld  --client_email=$email aegir.ld
  #   expect \") password:\"
  #   send \"mysql\r\"
  #   expect \"Do you really want to proceed with the install (y/n):\"
  #   send \"y\r\"
  #   expect eof"

  if [[ $(wget http://aegir.ld > /dev/null 2>&1 | egrep "HTTP" | awk {'print $6'}) != "404" ]] ; then
    rm index.html > /dev/null 2>&1
    printf "\n########\n# Changing some hostmaster varibles to defaults we like..\n########\n"
    drush @hostmaster vset hosting_feature_platform_pathauto 1
    drush @hostmaster vset hosting_feature_cron 0
    drush @hostmaster vset "hosting_feature_Cron queue" 0
    drush @hostmaster vset "hosting_feature_Hosting queue daemon" 1
    drush @hostmaster vset hosting_feature_queued 1
    drush @hostmaster vset hosting_queue_tasks_enabled 0
    drush @hostmaster vset hosting_require_disable_before_delete 0

    printf "\n########\n# Download and start hosting queue daemon launch agent..\n########\n"
    curl https://gist.githubusercontent.com/BrianGilbert/9226172/raw/509f69711a5a2c61ec41b6d3b690a72096b26703/org.aegir.hosting.queued.plist > ~/Library/LaunchAgents/org.aegir.hosting.queued.plist
    launchctl load -w ~/Library/LaunchAgents/org.aegir.hosting.queued.plist

    curl https://gist.githubusercontent.com/BrianGilbert/9282670/raw/3e77b7fc4baa5cb072b13156b943c9a4145eb86a/nginx_xhprof.ld.conf > /var/aegir/config/server_master/nginx/pre.d/nginx_xhprof.ld.conf

    printf "\n########\n# Installing registry_rebuild drush module\n########\n"
    drush dl registry_rebuild

    printf "\n########\n# Symlinking platforms to ~/Sites/Aegir..\n########\n"
    mkdir -p ~/Sites/Aegir
    rmdir /var/aegir/platforms
    ln -s ~/Sites/Aegir /var/aegir/platforms

    printf "\n########\n# Enabling SSL for local sites..\n########\n"
    mkdir -p /usr/local/etc/ssl/private;
    openssl req -x509 -nodes -days 7300 -subj "/C=US/ST=New York/O=Aegir/OU=Cloud/L=New York/CN=*.aegir.ld" -newkey rsa:2048 -keyout /usr/local/etc/ssl/private/nginx-wild-ssl.key -out /usr/local/etc/ssl/private/nginx-wild-ssl.crt -batch 2> /dev/null;
    curl https://gist.githubusercontent.com/BrianGilbert/7760457/raw/fa9163ecc533ae14ea1332b38444e03be00dd329/nginx_wild_ssl.conf > /var/aegir/config/server_master/nginx/pre.d/nginx_wild_ssl.conf;
    sudo /usr/local/bin/nginx -s reload;

    printf "\n########\n# Saving some instructional notes to ~/Desktop/YourAegirSetup.txt..\n########\n"
    say "saving some instructional notes to your desktop"
    echo "Hi fellow Drupaler,

Here is some important information about your local Aegir setup.

Creating and maintaining this takes a lot of time, you can help:
  https://www.gittip.com/Brian%20Gilbert/

The date.timezone value is set to Melbourne/Australia you may want
to change it to something that suits you better.

Your Aegir sites are accesible using http and https, though you
will need to trush the certificate in your browser.

To change it, depending on what versions of php you installed,
type each of these in terminal and search for Melbourne:
 nano /usr/local/etc/php/5.3/php.ini
 nano /usr/local/etc/php/5.4/php.ini
 nano /usr/local/etc/php/5.5/php.ini

Then restart nginx using:
 sudo /usr/local/bin/nginx -s reload

php53 is currently active, to switch the active version of php use
the following commands:
 go53
 go54
 go55

xdebug settings are configured as follows:
 xdebug.max_nesting_level = 200
 xdebug.profiler_enable = 1
 xdebug.profiler_enable_trigger = 1
 xdebug.profiler_output_name = xdebug-profile-cachegrind.out-%H-%R
 xdebug.profiler_output_dir = /tmp/xdebug/
 xdebug.remote_autostart = 0
 xdebug.remote_enable=1
 xdebug.remote_connect_back = 1
 xdebug.remote_port = 9001
 xdebug.remote_host = localhost
 xdebug.var_display_max_children = 128
 xdebug.var_display_max_data = 2048
 xdebug.var_display_max_depth = 32

The xdebug configuration files can be found at:
 /usr/local/etc/php/5.3/conf.d/ext-xdebug.ini
 /usr/local/etc/php/5.4/conf.d/ext-xdebug.ini
 /usr/local/etc/php/5.5/conf.d/ext-xdebug.ini

xhprof is setup for use with the devel module, configure and enable
it using the following settings:
 Enable profiling of all page views and drush requests = checked
 xhprof directory = /usr/local/opt/xhprof
 XHProf URL = http://xhprof.ld

I have tried to set DNS for commonly named network interfaces check
all of your interfaces to ensure that the DNS server is set to:
127.0.0.1

New Aegir platforms go in ~/Sites/Aegir/

If you configured mail sending email you will also have received an
email with a one time login link for your Aegir site.

If you elected to setup ApacheSolr the default port has been changed
to match the port used by Barracuda [1].
You can access the Solr4 WebUI at:
 http://localhost:8099/solr/

When you set up search_api_solr you will need to copy the contents
of the 4.x version of the solr-conf files that come with the module
into each core you set up, eg.:
 /usr/local/opt/solr/libexec/example/multicore/core0/conf

If you did not elect to load solr on boot you can run it by executing
the following in a terminal:
launchctl load ~/Library/LaunchAgents/com.apache.solr.plist
To stop it:
 launchctl unload ~/Library/LaunchAgents/com.apache.solr.plist

If things are not working after an OS update update then try the
following steps, reset DNS to 127.0.0.1 and run following command:
 sudo mkdir -p /var/log/nginx

Then start nginx:
 sudo /usr/local/bin/nginx

Please take the time to say thanks:
http://twitter.com/BrianGilbert_

Creating and maintaining this takes a lot of time, if it makes life easier
for you please consider making a donation:
Paypal: http://rl.cm/osxaegirdonation
Gittip: https://www.gittip.com/Brian%20Gilbert/

1. https://drupal.org/project/barracuda
" >> ~/Desktop/YourAegirSetup.txt

    printf "\n########\n# Attempting to email it to you as well..\n########\n"
    say "emailing it to you as well"
    mail -s 'Your local Aegir setup' ${EMAIL} < ~/Desktop/YourAegirSetup.txt

    printf "\n########\n# The date.timezone value in /usr/local/etc/php/[version]/php.ini\n# Is set to Melbourne/Australia\n# You may want to change it to something that suits you better.\n########\n"
    # printf "The mysql root password is set to 'mysql' and login is only possible from localhost..\n"
    printf "\n########\n# Double check your network interfaces to ensure their DNS server\n# is set to 127.0.0.1 as we only tried to set commonly named interfaces.\n########\n"
    printf "\n########\n# Please say thanks @BrianGilbert_  http://twiter.com/BrianGilbert_\n########\n"
    printf "\n########\n# Finished $(date +"%Y-%m-%d %H:%M:%S")\n########\n"
    open http://rl.cm/osxaegirwoot
    sleep 30;open http://rl.cm/osxaegirdonation
  else
    echo "\n########\n# Something has gone wrong!\n# The aegir.ld site isn't accesible.\n# you'll probably need to rerun the installation.\n########\n"
  fi
} 2>&1 | tee -a ~/Desktop/aegir-install-logfile-$(date +"%Y-%m-%d.%H.%M.%S").log
echo "###fin###"
exit
