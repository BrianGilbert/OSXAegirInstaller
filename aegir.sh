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

  # Set some variables for username, installing aegir, backups dir, and the OS X version
  USERNAME=${USER-$LOGNAME} #`ps -o user= $(ps -o ppid= $PPID)`
  DRUSH='drush --php=/usr/local/bin/php'
  BACKUPS_DIR=~/Desktop/aegir-install-backup-$(date +"%Y-%m-%d.%H.%M.%S")
  OSX=`sw_vers -productVersion | cut -c 1-5`

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

  if type "port" > /dev/null 2>&1; then
    printf "########\n# Attempting to uninstall macports..\n"
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
  else
    printf "########\n# macports isn't installed continuing..\n"
  fi

  if type "drush" > /dev/null 2>&1; then
    printf "########\n# Remove your existing version of drush first..\n########"
    exit
  else
    printf "########\n# Great, Drush isn't already installed continuing..\n"
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
  if [[ ${OSX} = 10.11 || ${OSX} = 10.10 || ${OSX} = 10.9. ]] ; then
    printf "# You're using $OSX, so let's go!\n########\n"
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
    printf "# Should I backup some important bits then remove it? \n# The option to re-install will be given after this, if you say no I'll prompt you to update the homebrew components. [Y/n]\n########\n"
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

        mkdir -p $BACKUPS_DIR

        printf "# Stopping and deleting any services that are already installed..\n########\n"
        if [ -e "/Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist" ] ; then
          sudo launchctl unload -w /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist
          sudo rm /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist
        fi

        if [ -e "/Library/LaunchDaemons/homebrew.mxcl.nginx.plist" ] ; then
          sudo launchctl unload -w /Library/LaunchDaemons/homebrew.mxcl.nginx.plist
          sudo rm /Library/LaunchDaemons/homebrew.mxcl.nginx.plist
        fi

        if [ -e "/Library/LaunchDaemons/homebrew.mxcl.nginx-full.plist" ] ; then
          sudo launchctl unload -w /Library/LaunchDaemons/homebrew.mxcl.nginx-full.plist
          sudo rm /Library/LaunchDaemons/homebrew.mxcl.nginx-full.plist
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

        if [ -e "~/Library/LaunchAgents/homebrew.mxcl.php56.plist" ] ; then
          launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php56.plist
          rm ~/Library/LaunchAgents/homebrew.mxcl.php56.plist
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
        sudo rm /var/log/aegir/php53-fpm.log
        rm /usr/local/bin/go53

        brew uninstall php54-geoip
        brew uninstall php54-imagick
        brew uninstall php54-mcrypt
        brew uninstall php54-uploadprogress
        brew uninstall php54-xdebug
        brew uninstall php54-xhprof
        brew uninstall php54
        sudo rm /var/log/nginx/php54-fpm.log
        sudo rm /var/log/aegir/php54-fpm.log
        rm /usr/local/bin/go54

        brew uninstall php55-geoip
        brew uninstall php55-imagick
        brew uninstall php55-mcrypt
        brew uninstall php55-uploadprogress
        brew uninstall php55-xdebug
        brew uninstall php55-xhprof
        brew uninstall php55
        sudo rm /var/log/nginx/php55-fpm.log
        sudo rm /var/log/aegir/php55-fpm.log
        rm /usr/local/bin/go55

        brew uninstall php56-geoip
        brew uninstall php56-imagick
        brew uninstall php56-mcrypt
        brew uninstall php56-uploadprogress
        brew uninstall php56-xdebug
        brew uninstall php56-xhprof
        brew uninstall php56
        sudo rm /var/log/nginx/php56-fpm.log
        sudo rm /var/log/aegir/php56-fpm.log
        rm /usr/local/bin/go56

        rm -rf /usr/local/etc/php

        brew uninstall php-code-sniffer
        brew uninstall drupal-code-sniffer
        brew uninstall phpunit

        brew untap josegonzalez/php

        brew uninstall re2c
        brew uninstall flex
        brew uninstall bison27
        brew uninstall libevent
        brew uninstall openssl
        brew uninstall solr

        sudo mv /var/log/nginx/access.log $BACKUPS_DIR/brew.nginx.access.log
        sudo mv /var/log/nginx/error.log $BACKUPS_DIR/brew.nginx.error.log
        sudo mv /var/log/aegir/access.log $BACKUPS_DIR/brew.nginx.access.log
        sudo mv /var/log/aegir/error.log $BACKUPS_DIR/brew.nginx.error.log
        rm -rf /usr/local/etc/nginx
        rm -rf /usr/local/var/run/nginx
        sudo rm /var/log/nginx/error.log
        sudo rm /var/log/aegir/error.log
        brew uninstall nginx
        brew uninstall nginx-full

        brew uninstall pcre geoip
        rm -rf /usr/local/share/GeoIP
        brew uninstall dnsmasq
        sudo networksetup -setdnsservers AirPort empty
        sudo networksetup -setdnsservers Ethernet empty
        sudo networksetup -setdnsservers 'Thunderbolt Ethernet' empty
        sudo networksetup -setdnsservers Wi-Fi empty
        sudo mv /etc/resolv.dnsmasq.conf $BACKUPS_DIR
        sudo mv /usr/local/etc/dnsmasq.conf $BACKUPS_DIR
        sudo mv /etc/resolver/default $BACKUPS_DIR/resolver.default
        sudo mv /etc/resolver/ld $BACKUPS_DIR/resolver.ld
        sudo mv /usr/local/etc/dnsmasq.hosts $BACKUPS_DIR
        sudo networksetup -setdnsservers AirPort empty
        sudo networksetup -setdnsservers Ethernet empty
        sudo networksetup -setdnsservers 'Thunderbolt Ethernet' empty
        sudo networksetup -setdnsservers Wi-Fi empty

        printf "# Removing previous drush installation, this may error..\n########\n"
        brew uninstall composer
        brew uninstall drush
        brew uninstall gzip
        brew uninstall wget
        printf "# Removing related configurations..\n########\n"
        sudo launchctl unload /System/Library/LaunchDaemons/org.postfix.master.plist
        sudo mv /etc/postfix/sasl_passwd $BACKUPS_DIR/postfix.sasl_passwd
        sudo mv /etc/postfix/main.cf $BACKUPS_DIR/postfix.main.cf
        sudo cp /etc/postfix/main.cf.orig /etc/postfix/main.cf
        rm ~/.forward

        say "Do you want to create backups of your databases?"
        printf "# Do you want to backup all existing databases?\n# If you say no here make sure you have backups from your databases.\n# Answer [Y/n]\n########\n"
        read -n1 DBBACKUP
        if [[ $DBBACKUP =~ ^(y|Y)$ ]]; then
          mkdir -p $BACKUPS_DIR/databases
          printf "\n# What is your current MariaDB root password? \n########\n"
          read DBPASS passw
          DBLIST="$(mysql -uroot -h localhost -p$DBPASS -Bse 'show databases')"
          if [ ${#DBLIST} -gt 0 ]; then
            printf "\n# Backing up databases..\n########\n"
            for DBITEM in $DBLIST
            do
              if [ "$DBITEM" != "performance_schema" ]; then
                printf "\n# Database: $DBITEM"
                FILE=$BACKUPS_DIR/databases/$DBITEM.$NOW-$(date +"%Y-%m-%d.%H.%M.%S").sql
                mysqldump --events --single-transaction -u root -h localhost -p$DBPASS $DBITEM > $FILE
                tar czfP $FILE.tar.gz $FILE
                rm $FILE
              fi
            done
          fi
        fi

        printf "\n########\n# Now removing mariadb and all databases..\n########\n"
        rm ~/Library/LaunchAgents/homebrew.mxcl.mariadb.plist
        brew uninstall mariadb
        mv /usr/local/etc/my-drupal.cnf $BACKUPS_DIR
        mv /usr/local/etc/my.cnf $BACKUPS_DIR/local.etc.my.cnf
        mv  /usr/local/etc/my.cnf.d $BACKUPS_DIR
        sudo mv /etc/my.cnf $BACKUPS_DIR/etc.my.cnf
        rm -rf /usr/local/var/mysql
        sudo killall mysqld

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
        sudo killall php-fpm

        mv ~/Desktop/YourAegirSetup.txt $BACKUPS_DIR/YourAegirSetup.txt-.pre-uninstall-$(date +"%Y-%m-%d.%H.%M.%S")

        printf "# Renaming your Aegir folder to /var/aegir.pre-uninstall-TI-ME-ST-AM-P....\n########\n"
        sudo mv /var/aegir $BACKUPS_DIR/aegir-config-pre-uninstall-$(date +"%Y-%m-%d.%H.%M.%S")
        mv ~/.drush/provision $BACKUPS_DIR/aegir-config-pre-uninstall-$(date +"%Y-%m-%d.%H.%M.%S")

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
    else
      printf "# Should I attempt an upgrade of the homebrew components? [Y/n]\n########\n"
      say "Should try an  of homebrews bits?"
      read UPGRADE
      if [[ $UPGRADE =~ ^(y|Y)$ ]]; then

        # printf "# Should I install the dev version of Aegir? [Y/n]\n########\n"
        # read DEV
        # if [[ $DEV =~ ^(y|Y)$ ]]; then
        #   INSTALL = '7.x-3.x';
        # else
        #   INSTALL = '6.x-2.1';
        # fi

        # if [ -d "/var/aegir/hostmaster-6.x-2.x" ]; then
        #   # Control will enter here if 6.x-2.0 directory exists.
        #   CURRENTINSTALL = '/var/aegir/hostmaster-6.x-2.x';
        # fi

        # if [ -d "/var/aegir/hostmaster-6.x-2.0" ]; then
        #   # Control will enter here if 6.x-2.0 directory exists.
        #   CURRENTINSTALL = '/var/aegir/hostmaster-6.x-2.0';
        # fi

        # if [ -d "/var/aegir/hostmaster-6.x-2.1" ]; then
        #   # Control will enter here if 6.x-2.0 directory exists.
        #   CURRENTINSTALL = '/var/aegir/hostmaster-6.x-2.1';
        # fi

        # if [ -d "/var/aegir/hostmaster-7.x-3.x" ]; then
        #   # Control will enter here if 7.x-3.x directory exists.
        #   CURRENTINSTALL = '/var/aegir/hostmaster-7.x-3.x';
        # fi

        printf "# Upgrading homebrew components...\n########\n"
        brew update
        brew upgrade apple-gcc42
        brew upgrade wget
        brew upgrade curl --with-homebrew-openssl
        brew upgrade gzip
        brew upgrade libpng
        brew upgrade dnsmasq
        brew upgrade pcre geoip
        brew upgrade nginx-full --with-debug --with-flv --with-geoip --with-gzip-static --with-webdav --with-mp4 --with-spdy --with-ssl --with-status --with-upload-progress-module
        if [ -e "/Library/LaunchDaemons/homebrew.mxcl.nginx.plist" ] ; then
          sudo rm /Library/LaunchDaemons/homebrew.mxcl.nginx.plist
          sudo cp $(brew --prefix nginx-full)/homebrew.mxcl.nginx-full.plist /Library/LaunchDaemons/
        fi
        echo "update path to nginx logfiles, you'll need to enter password here."
        sudo mkdir -p /var/log/aegir
        sudo chown -R ${USERNAME}:admin /var/log/aegir
        sudo rm /var/log/nginx/error.log
        sudo rm /var/log/aegir/nginx-error.log

        brew upgrade cmake

        launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.mariadb.plist
        brew upgrade mariadb
        launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.mariadb.plist

        PHPAVAIL=`ls -d /usr/local/Cellar/php5* | grep 'php5[0-9]$' | cut -c 22-24`
        PHPLIVE=`php --version |grep 5|cut -c 5-7`

        launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php53.plist > /dev/null 2>&1
        rm ~/Library/LaunchAgents/homebrew.mxcl.php53.plist
        launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php54.plist > /dev/null 2>&1
        rm ~/Library/LaunchAgents/homebrew.mxcl.php54.plist
        launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php55.plist > /dev/null 2>&1
        rm ~/Library/LaunchAgents/homebrew.mxcl.php55.plist
        launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php56.plist > /dev/null 2>&1
        rm ~/Library/LaunchAgents/homebrew.mxcl.php56.plist

        if [[ ${PHPAVAIL} == *"56"* ]] ; then
          sudo rm -rf $(brew --prefix homebrew/php/php56)/var
          brew unlink php53 > /dev/null 2>&1
          brew unlink php54 > /dev/null 2>&1
          brew unlink php55 > /dev/null 2>&1
          brew link php56
          brew upgrade php56 --without-snmp --with-fpm --with-gmp --with-imap --with-mysql --with-homebrew-curl --with-homebrew-libxslt --with-homebrew-curl --with-homebrew-openssl
          brew upgrade php56-geoip
          brew upgrade php56-imagick
          brew upgrade php56-mcrypt
          brew upgrade php56-uploadprogress
          brew upgrade php56-xdebug
          brew upgrade php56-xhprof
          sudo rm /var/log/nginx/php56-fpm.log
          sudo rm /var/log/aegir/php56-fpm.log
          cp $(brew --prefix homebrew/php/php56)/homebrew.mxcl.php56.plist ~/Library/LaunchAgents/
          brew unlink php56
        fi

        if [[ ${PHPAVAIL} == *"55"* ]] ; then
          sudo rm -rf $(brew --prefix homebrew/php/php55)/var
          brew unlink php53 > /dev/null 2>&1
          brew unlink php54 > /dev/null 2>&1
          brew unlink php56 > /dev/null 2>&1
          brew link php55
          brew upgrade php55 --without-snmp --with-fpm --with-gmp --with-imap --with-mysql --with-homebrew-curl --with-homebrew-libxslt --with-homebrew-curl --with-homebrew-openssl
          brew upgrade php55-geoip
          brew upgrade php55-imagick
          brew upgrade php55-mcrypt
          brew upgrade php55-uploadprogress
          brew upgrade php55-xdebug
          brew upgrade php55-xhprof
          sudo rm /var/log/nginx/php55-fpm.log
          sudo rm /var/log/aegir/php55-fpm.log
          cp $(brew --prefix homebrew/php/php55)/homebrew.mxcl.php55.plist ~/Library/LaunchAgents/
          brew unlink php55
        fi

        if [[ ${PHPAVAIL} == *"54"* ]] ; then
          sudo rm -rf $(brew --prefix homebrew/php/php54)/var
          brew unlink php53 > /dev/null 2>&1
          brew unlink php55 > /dev/null 2>&1
          brew unlink php56 > /dev/null 2>&1
          brew link php54
          brew upgrade php54 --without-snmp --with-fpm --with-gmp --with-imap --with-mysql --with-homebrew-curl --with-homebrew-libxslt --with-homebrew-curl --with-homebrew-openssl
          brew upgrade php54-geoip
          brew upgrade php54-imagick
          brew upgrade php54-mcrypt
          brew upgrade php54-uploadprogress
          brew upgrade php54-xdebug
          brew upgrade php54-xhprof
          sudo rm /var/log/nginx/php54-fpm.log
          sudo rm /var/log/aegir/php54-fpm.log
          cp $(brew --prefix homebrew/php/php54)/homebrew.mxcl.php54.plist ~/Library/LaunchAgents/
          brew unlink php54
        fi

        if [[ ${PHPAVAIL} == *"53"* ]] ; then
          sudo rm -rf $(brew --prefix homebrew/php/php53)/var
          brew unlink php54 > /dev/null 2>&1
          brew unlink php55 > /dev/null 2>&1
          brew unlink php56 > /dev/null 2>&1
          brew link php53
          brew upgrade re2c
          brew upgrade flex
          brew upgrade bison27
          brew upgrade libevent
          brew upgrade php53 --without-snmp --with-fpm --with-gmp --with-imap --with-mysql --with-homebrew-curl --with-homebrew-libxslt --with-homebrew-curl --with-homebrew-openssl
          brew upgrade php53-geoip
          brew upgrade php53-imagick
          brew upgrade php53-mcrypt
          brew upgrade php53-uploadprogress
          brew upgrade php53-xdebug
          brew upgrade php53-xhprof
          sudo rm /var/log/nginx/php53-fpm.log
          sudo rm /var/log/aegir/php53-fpm.log
          cp $(brew --prefix homebrew/php/php53)/homebrew.mxcl.php53.plist ~/Library/LaunchAgents/

          brew unlink php53
        fi

        if [[ ${PHPAVAIL} == *"53"* ]] ; then
          brew link php53
          launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.php53.plist
        fi

        if [[ ${PHPAVAIL} == *"54"* ]] ; then
          brew link php54
          launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.php54.plist
        fi

        if [[ ${PHPAVAIL} == *"55"* ]] ; then
          brew link php55
          launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.php55.plist
        fi

        if [[ ${PHPAVAIL} == *"56"* ]] ; then
          brew link php56
          launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.php56.plist
        fi
        mkdir -p /usr/local/share/GeoIP
        curl http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz > /usr/local/share/GeoIP/GeoIP.dat.gz
        gunzip -f GeoIP.dat.gz &> /dev/null

        brew upgrade php-code-sniffer
        brew upgrade drupal-code-sniffer
        brew upgrade phpunit
        brew upgrade homebrew/php/composer
        composer global require drush/drush:dev-master

        HAVESOLR=`ls -d /usr/local/Cellar/solr`

        if [[ ${HAVESOLR} == *"solr"* ]] ; then
          brew upgrade solr
        fi

        brew cleanup

        # # Aegir upgrade
        # say "Input will be required."
        # $DRUSH dl --destination=/Users/admin/.drush provision-{$INSTALL};
        # $DRUSH cache-clear drush
        # OLD_AEGIR_DIR={$CURRENTINSTALL};
        # AEGIR_VERSION={$INSTALL};
        # AEGIR_DOMAIN=aegir.ld;
        # cd $OLD_AEGIR_DIR;
        # drush hostmaster-migrate $AEGIR_DOMAIN /var/aegir/hostmaster-$AEGIR_VERSION --debug
        exit
      else
        printf "# Exiting..\n########\n"
        say "Exiting."
        exit
      fi
    fi
  fi

  # printf "\n########\n# If xcode is installed check it's license has been agreed to..\n########\n"
  # xcode-select -p > /dev/null 2&>1
  # if [[ $? -eq 127 ]] ; then
  #   printf "########\n# xcode isn't installed continuing..\n"
  # else
  #   printf "########\n# ensuring xcode license has been agreed to..\nn"
  #   xcodebuild -license
  # fi

  printf "\n########\n# Checking if Homebrew is installed..\n########\n"
  if type "brew" > /dev/null 2>&1; then
    printf "\n########\n# Affirmative! Let's make sure everything is up to date..\n# Just so you know, this may throw a few warnings..\n########\n"
    say "Making sure homebrew is up to date, you may see some errors in the output, that's ok."
    export PATH=/usr/local/bin:/usr/local/sbin:${HOME}/.composer/vendor/bin:${PATH}
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
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    echo "export PATH=/usr/local/bin:/usr/local/sbin:${HOME}/.composer/vendor/bin:${PATH}" >> ~/.bash_profile
    echo "export PATH=/usr/local/bin:/usr/local/sbin:${HOME}/.composer/vendor/bin:${PATH}" >> ~/.zshrc
    source ~/.bash_profile
  fi

  printf "\n########\n# Doing some setup ready for Aegir install..\n########\n"
  sudo mkdir -p /var/aegir
  sudo chown ${USERNAME} /var/aegir
  sudo chgrp staff /var/aegir
  echo "$(date +"%Y-%m-%d %H:%M:%S")" > /var/aegir/.osxaegir
  sudo dscl . append /Groups/_www GroupMembership ${USERNAME}

  echo "
# Your hostname will be set to aegir.ld
########
# Install the developmental version of Aegir (7.x-3.x)? [Y/n]:
########"
  say "input required"
  read -n1 AEGIR7X
  if [[ ${AEGIR7X} =~ ^(y|Y)$ ]]; then
    printf "\n# You entered Y\n########\n"
  else
    printf "\n# You entered N\n########\n"
  fi

  echo "
########
# I can install multiple versions of PHP; 5.3, 5.4 5.5 and/or 5.6.
# Let me know which versions you'd like installed.
# Set up PHP 5.3 [Y/n]:
########"
  say "input required"
  read -n1 PHP53
  if [[ ${PHP53} =~ ^(y|Y)$ ]]; then
    printf "\n# You entered Y\n########\n"
  else
    printf "\n# You entered N\n########\n"
  fi

  if [[ ${PHP53} =~ ^(y|Y)$ ]]; then
    echo "
########
# Make PHP 5.3 the default [Y/n]:
########"
    say "input required"
    read -n1 PHP53DEF
    if [[ ${PHP53DEF} =~ ^(y|Y)$ ]]; then
      printf "\n# You entered Y\n########\n"
    else
      printf "\n# You entered N\n########\n"
    fi
  fi

  echo "
########
# Set up PHP 5.4 [Y/n]:
########"
  say "input required"
  read -n1 PHP54
  if [[ ${PHP54} =~ ^(y|Y)$ ]]; then
    printf "\n# You entered Y\n########\n"
  else
    printf "\n# You entered N\n########\n"
  fi

  if [[ ! ${PHP53DEF} =~ ^(y|Y)$ ]]; then
    if [[ ${PHP54} =~ ^(y|Y)$ ]]; then
      echo "
########
# Make PHP 5.4 the default [Y/n]:
########"
      say "input required"
      read -n1 PHP54DEF
      if [[ ${PHP54DEF} =~ ^(y|Y)$ ]]; then
        printf "\n# You entered Y\n########\n"
      else
        printf "\n# You entered N\n########\n"
      fi
    fi
  fi

  echo "
########
# Set up PHP 5.5 [Y/n]:
########"
  say "input required"
  read -n1 PHP55
  if [[ ${PHP55} =~ ^(y|Y)$ ]]; then
    printf "\n# You entered Y\n########\n"
  else
    printf "\n# You entered N\n########\n"
  fi

  if [[ ${PHP53DEF} =~ ^(y|Y)$ || ${PHP54DEF} =~ ^(y|Y)$ ]]; then
    echo ""
  else
    echo "
########
# Make PHP 5.5 the default [Y/n]:
########"
    say "input required"
    read -n1 PHP55DEF
    if [[ ${PHP55DEF} =~ ^(y|Y)$ ]]; then
      printf "\n# You entered Y\n########\n"
    else
      printf "\n# You entered N\n########\n"
    fi
  fi

  echo "
########
# Set up PHP 5.6 [Y/n]:
########"
  say "input required"
  read -n1 PHP56
  if [[ ${PHP56} =~ ^(y|Y)$ ]]; then
    printf "\n# You entered Y\n########\n"
  else
    printf "\n# You entered N\n########\n"
  fi

  if [[ ${PHP53DEF} =~ ^(y|Y)$ || ${PHP54DEF} =~ ^(y|Y)$ || ${PHP55DEF} =~ ^(y|Y)$ ]]; then
    echo ""
  else
    echo "
########
# Make PHP 5.6 the default [Y/n]:
########"
    say "input required"
    read -n1 PHP56DEF
    if [[ ${PHP56DEF} =~ ^(y|Y)$ ]]; then
      printf "\n# You entered Y\n########\n"
    else
      printf "\n# You entered N\n########\n"
    fi
  fi

  if [[ ! ${PHP53} =~ ^(y|Y)$ && ! ${PHP54} =~ ^(y|Y)$ && ! ${PHP55} =~ ^(y|Y)$ ]]; then
    echo "
########
# You didn't select any version of PHP?!? So I'm installing PHP5.6
########"
  PHP56="Y"
  PHP56DEF="Y"
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
    printf "\n# You entered Y\n########\n"
  fi

  # Tap required kegs
  printf "\n########\n# Now we'll tap some extra kegs we need..\n########\n"
  brew tap homebrew/versions
  brew tap homebrew/dupes
  brew tap homebrew/homebrew-php
  brew tap homebrew/nginx
  brew update
  brew doctor

  # Install required formula's
  printf "# Installing required brew formulae..\n########\n"
  printf "# Installing cask..\n########\n"
  brew install caskroom/cask/brew-cask
  printf "# Installing gcc..\n########\n"
  brew install apple-gcc42
  printf "\n########\n# Installing java8..\n########\n"
  say "You may need to enter your password now"
  brew cask install java
  printf "\n########\n# Installing wget..\n########\n"
  brew install wget
  printf "\n########\n# Installing curl..\n########\n"
  brew install --with-openssl curl
  printf "\n########\n# Installing gzip..\n########\n"
  brew install gzip
  printf "\n########\n# Installing libpng..\n########\n"
  brew install libpng
  printf "\n########\n# Installing dnsmasq..\n########\n"
  brew install dnsmasq
  printf "\n########\n# Configuring dnsmasq..\n########\n"
  mkdir -p /usr/local/etc

  # Configure dnsmasq
  printf "########\n# Setting up wildcard DNS so that domains ending in dot ld will resolve to your local machine\n"
  if [ -e "/usr/local/etc/dnsmasq.conf" ] ; then
    printf "########\n# You already have a dnsmasq.conf file..\n# So this all works proerly I'm going to backup and recreate it..\n########\n"
    mv /usr/local/etc/dnsmasq.conf $BACKUPS_DIR
  fi

  printf "# Setting dnsmasq config..\n########\n"
  cp $(brew --prefix dnsmasq)/dnsmasq.conf.example /usr/local/etc/dnsmasq.conf
  echo '# Edited by OSX Aegir install script' | cat - /usr/local/etc/dnsmasq.conf > temp && mv temp /usr/local/etc/dnsmasq.conf
  echo "\nresolv-file=/etc/resolv.dnsmasq.conf" >> /usr/local/etc/dnsmasq.conf
  echo "address=/.ld/127.0.0.1" >> /usr/local/etc/dnsmasq.conf
  echo "listen-address=127.0.0.1" >> /usr/local/etc/dnsmasq.conf
  echo "addn-hosts=/usr/local/etc/dnsmasq.hosts" >> /usr/local/etc/dnsmasq.conf
  touch /usr/local/etc/dnsmasq.hosts

  if [ -e "/etc/resolv.dnsmasq.conf" ] ; then
    printf "# You already have a resolv.conf set..\n# So this all works properly I'm going to backup and recreate it..\n########\n"
    say "You may be prompted for your password"
    sudo mv /etc/resolv.dnsmasq.conf $BACKUPS_DIR
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

  if [ -e "/etc/resolver/ld" ] ; then
    printf "# You already have a resolver set for when you are offline..\n# So this all works properly I'm going to backup and recreate it..\n########\n"
    say "You may be prompted for your password"
    sudo mv /etc/resolver/ $BACKUPS_DIR
  fi

  printf "########\n# Making local domains resolve when your disconnected from net..\n########\n"
  sudo mkdir -p /etc/resolver
  sudo sh -c 'echo "nameserver 127.0.0.1" >> /etc/resolver/ld'

  printf "# Setting hostname to aegir.ld\n########\n"
  sudo scutil --set HostName aegir.ld

  # Start dnsmasq
  printf "# Copying dnsmasq launch daemon into place..\n########\n"
  sudo cp $(brew --prefix dnsmasq)/homebrew.mxcl.dnsmasq.plist /Library/LaunchDaemons
  printf "# Starting dnsmasq..\n########\n"
  sudo launchctl load -w /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist

  printf "\n########\n# Installing nginx..\n########\n"
  brew install pcre geoip
  brew install nginx-full --with-debug --with-flv --with-geoip --with-gzip-static --with-webdav --with-mp4 --with-spdy --with-ssl --with-status --with-upload-progress-module
  printf "\n########\n# Configuring nginx..\n########\n"
  if [ -e "/usr/local/etc/nginx/nginx.conf" ] ; then
  mv /usr/local/etc/nginx/nginx.conf /usr/local/etc/nginx/nginx.conf.bak
  fi
  curl https://gist.githubusercontent.com/BrianGilbert/5908352/raw/097a8128efd6815dbbacd18339b60c0ad780f65f/nginx.conf > /usr/local/etc/nginx/nginx.conf
  sed -i '' 's/\[username\]/'${USERNAME}'/' /usr/local/etc/nginx/nginx.conf

  mkdir -p /usr/local/etc/nginx/conf.d

  say "You may be prompted for your password"
  sudo mkdir -p /var/log/aegir
  sudo chown -R ${USERNAME}:admin /var/log/aegir
  sudo mkdir -p /var/lib/nginx
  mkdir -p /usr/local/var/run/nginx/proxy_temp

  mkdir -p /usr/local/share/GeoIP
  curl http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz > /usr/local/share/GeoIP/GeoIP.dat.gz
  gunzip -f GeoIP.dat.gz &> /dev/null

  printf "\n########\n# Installing mariadb..\n########\n"
  brew install cmake
  brew install mariadb
  unset TMPDIR
  printf "\n########\n# Configuring mariadb..\n########\n"
  mkdir -p /usr/local/etc/my.cnf.d
  mysql_install_db --user=${USERNAME} --basedir="$(brew --prefix mariadb)" --datadir=/usr/local/var/mysql --tmpdir=/tmp
  curl https://gist.githubusercontent.com/BrianGilbert/6207328/raw/10e298624ede46e361359b78a1020c82ddb8b943/my-drupal.cnf > /usr/local/etc/my.cnf.d/my-drupal.cnf
  say "You may be prompted for your password"

if [[ ${PHP56} =~ ^(y|Y)$ ]]; then
  printf "\n########\n# Installing php56..\n########\n"
  brew install php56 --without-snmp --with-fpm --with-gmp --with-imap --with-mysql --with-homebrew-curl --with-homebrew-libxslt --with-homebrew-openssl
  brew install php56-geoip
  brew install php56-imagick
  brew install php56-mcrypt
  brew install php56-uploadprogress
  brew install php56-xdebug
  brew install php56-xhprof

  # Make sure LaunchAgents directory exists
  mkdir -p ~/Library/LaunchAgents

  printf "\n########\n# Configuring php56..\n########\n"
  sed -i '' '/timezone =/ a\
  date.timezone = Australia/Melbourne\
  ' /usr/local/etc/php/5.6/php.ini
  sed -i '' 's/post_max_size = .*/post_max_size = '50M'/' /usr/local/etc/php/5.6/php.ini
  sed -i '' 's/upload_max_filesize = .*/upload_max_filesize = '10M'/' /usr/local/etc/php/5.6/php.ini
  sed -i '' 's/max_execution_time = .*/max_execution_time = '90'/' /usr/local/etc/php/5.6/php.ini
  sed -i '' 's/memory_limit = .*/memory_limit = '512M'/' /usr/local/etc/php/5.6/php.ini
  sed -i '' 's/pdo_mysql.default_socket=.*/pdo_mysql.default_socket= \/tmp\/mysql.sock/' /usr/local/etc/php/5.6/php.ini
  sed -i '' '/pid = run/ a\
  pid = /usr/local/var/run/php-fpm.pid\
  ' /usr/local/etc/php/5.6/php-fpm.conf

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
xdebug.var_display_max_depth = 32" >> /usr/local/etc/php/5.6/conf.d/ext-xdebug.ini

  say "You may be prompted for your password"
  sudo ln -s $(brew --prefix homebrew/php/php56)/var/log/php-fpm.log /var/log/aegir/php56-fpm.log

  cp $(brew --prefix homebrew/php/php56)/homebrew.mxcl.php56.plist ~/Library/LaunchAgents/

  echo "#!/bin/sh
# Written by Brian Gilbert @BrianGilbert_ https://github.com/BrianGilbert
# of Realityloop @Realityloop http://realitylop.com/

# Remove old symlink for xhprof and create correct one for this version of php
rm /usr/local/opt/xhprof > /dev/null 2>&1
ln -s  $(brew --prefix php56-xhprof) /usr/local/opt/xhprof

# Stop php-fpm and start correct version
launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php53.plist > /dev/null 2>&1
launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php54.plist > /dev/null 2>&1
launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php55.plist > /dev/null 2>&1
launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php56.plist > /dev/null 2>&1
launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.php56.plist

# Brew link correct php version
brew unlink php53 > /dev/null 2>&1
brew unlink php54 > /dev/null 2>&1
brew unlink php55 > /dev/null 2>&1
brew link php56

# Restart nginx
sudo /usr/local/bin/nginx -s reload" >> /usr/local/bin/go56
  chmod 755 /usr/local/bin/go56

  brew unlink php56
fi

if [[ ${PHP55} =~ ^(y|Y)$ ]]; then
  printf "\n########\n# Installing php55..\n########\n"
  brew install php55 --without-snmp --with-fpm --with-gmp --with-imap --with-mysql --with-homebrew-curl --with-homebrew-libxslt --with-homebrew-openssl
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
  sudo ln -s $(brew --prefix homebrew/php/php55)/var/log/php-fpm.log /var/log/aegir/php55-fpm.log

  cp $(brew --prefix homebrew/php/php55)/homebrew.mxcl.php55.plist ~/Library/LaunchAgents/

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
launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php56.plist > /dev/null 2>&1
launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.php55.plist

# Brew link correct php version
brew unlink php53 > /dev/null 2>&1
brew unlink php54 > /dev/null 2>&1
brew unlink php56 > /dev/null 2>&1
brew link php55

# Restart nginx
sudo /usr/local/bin/nginx -s reload" >> /usr/local/bin/go55
  chmod 755 /usr/local/bin/go55

  brew unlink php55
fi

if [[ ${PHP54} =~ ^(y|Y)$ ]]; then
  printf "\n########\n# Installing php54..\n########\n"
  brew install php54 --without-snmp --with-fpm --with-gmp --with-imap --with-mysql --with-homebrew-curl --with-homebrew-libxslt --with-homebrew-openssl
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
  sudo ln -s $(brew --prefix homebrew/php/php54)/var/log/php-fpm.log /var/log/aegir/php54-fpm.log

  mkdir -p ~/Library/LaunchAgents
  cp $(brew --prefix homebrew/php/php54)/homebrew.mxcl.php54.plist ~/Library/LaunchAgents/

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
launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php56.plist > /dev/null 2>&1
launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.php54.plist

# Brew link correct php version
brew unlink php53 > /dev/null 2>&1
brew unlink php55 > /dev/null 2>&1
brew unlink php56 > /dev/null 2>&1
brew link php54

# Restart nginx
sudo /usr/local/bin/nginx -s reload" >> /usr/local/bin/go54
  chmod 755 /usr/local/bin/go54

  brew unlink php54
fi

if [[ ${PHP53} =~ ^(y|Y)$ ]]; then
  printf "\n########\n# Installing php53 prerequisites..\n########\n"
  brew install re2c
  brew install flex
  brew install bison27
  brew install libevent
  printf "\n########\n# Installing php53..\n########\n"
  brew install php53 --without-snmp --with-fpm --with-gmp --with-imap --with-mysql --with-homebrew-curl --with-homebrew-libxslt --with-homebrew-openssl
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
  sudo ln -s $(brew --prefix homebrew/php/php53)/var/log/php-fpm.log /var/log/aegir/php53-fpm.log

  cp $(brew --prefix homebrew/php/php53)/homebrew.mxcl.php53.plist ~/Library/LaunchAgents/

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
launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php56.plist > /dev/null 2>&1
launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.php53.plist

# Brew link correct php version
brew unlink php54 > /dev/null 2>&1
brew unlink php55 > /dev/null 2>&1
brew unlink php56 > /dev/null 2>&1
brew link php53

# Restart nginx
sudo /usr/local/bin/nginx -s reload" >> /usr/local/bin/go53
  chmod 755 /usr/local/bin/go53

  brew unlink php53
fi

if [[ ${PHP53DEF} =~ ^(y|Y)$ ]]; then
  brew link php53
fi
if [[ ${PHP54DEF} =~ ^(y|Y)$ ]]; then
  brew link php54
fi
if [[ ${PHP55DEF} =~ ^(y|Y)$ ]]; then
  brew link php55
fi
if [[ ${PHP56DEF} =~ ^(y|Y)$ ]]; then
  brew link php56
fi

  printf "\n########\n# Installing php code sniffer..\n########\n"
  brew install php-code-sniffer
  printf "\n########\n# Installing drupal code sniffer..\n########\n"
  brew install drupal-code-sniffer
  printf "\n########\n# Installing phpunit..\n########\n"
  brew install phpunit

  printf "########\n# Installing composer..\n########\n"
  brew install homebrew/php/composer

  printf "\n########\n# Installing drush..\n########\n"
  # Uninstall drush if it was previously installed via homebrew
  brew uninstall drush > /dev/null 2&>1

  if [[ ${AEGIR7X} =~ ^(y|Y)$ ]]; then
    composer global require drush/drush:7.x
  else
    composer global require drush/drush:7.x
  fi

  #Solr
  if [[ ${SOLR} =~ ^(y|Y)$ ]]; then
    printf "\n########\n# Installing solr..\n########\n"
    brew install solr4
    printf "\n########\n# Backing up default multicore config..\n########\n"
    cp -rp $(brew --prefix solr4)/example/multicore $(brew --prefix solr4)/example/multicore.bak
    mkdir -p /usr/local/etc/solr4
    cp -rp $(brew --prefix solr4)/example/multicore /usr/local/etc/solr4/multicore
    mkdir -p /usr/local/var/log/solr4
    curl https://gist.githubusercontent.com/BrianGilbert/ddd8dd9be78dc3d0201d/raw/03b303cfd696026e26f738e9b1200ce45a36ee5f/homebrew.mxcl.solr4.plist > ~/Library/LaunchAgents/homebrew.mxcl.solr4.plist
  fi

  printf "\n########\n# Setting up launch daemons..\n########\n"
  say "you may be prompted for your password"
  sudo cp $(brew --prefix nginx-full)/homebrew.mxcl.nginx-full.plist /Library/LaunchDaemons/
  sudo chown root:wheel /Library/LaunchDaemons/homebrew.mxcl.nginx-full.plist

  cp $(brew --prefix mariadb)/homebrew.mxcl.mariadb.plist ~/Library/LaunchAgents/

  sudo mkdir -p /var/log/nginx
  ln -s /var/log/nginx/access.log /var/log/aegir/nginx-access.log

  printf "\n########\n# Launching daemons now..\n########\n"
  sudo launchctl load -w /Library/LaunchDaemons/homebrew.mxcl.nginx-full.plist
  launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.mariadb.plist
  if [[ ${PHP55DEF} =~ ^(y|Y)$ ]]; then
    launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php55.plist > /dev/null 2>&1
    launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php54.plist > /dev/null 2>&1
    launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php53.plist > /dev/null 2>&1
    launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.php56.plist
  fi
  if [[ ${PHP55DEF} =~ ^(y|Y)$ ]]; then
    launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php56.plist > /dev/null 2>&1
    launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php54.plist > /dev/null 2>&1
    launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php53.plist > /dev/null 2>&1
    launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.php55.plist
  fi
  if [[ ${PHP54DEF} =~ ^(y|Y)$ ]]; then
    launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php56.plist > /dev/null 2>&1
    launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php55.plist > /dev/null 2>&1
    launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php53.plist > /dev/null 2>&1
    launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.php54.plist
  fi
  if [[ ${PHP53DEF} =~ ^(y|Y)$ ]]; then
    launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.php56.plist > /dev/null 2>&1
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
# Current password: <hit enter>
# Set root password?: [Y/n] y
# New password: <make it easy, eg. mysql>
# Remove anonymous users? [Y/n] y
# Disallow root login remotely? [Y/n] y
# Remove test database and access to it? [Y/n] y
# Reload privilege tables now? [Y/n] y
########" #remove this echo when expects block below is fixed.
  say "Read the block above and enter responses as shown when propted"

  sudo PATH="/usr/local/bin:/usr/local/sbin:$HOME/.composer/vendor/bin:${PATH}" $(brew --prefix mariadb)/bin/mysql_secure_installation #remove this line when expects block below is fixed.
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
  ln -s /var/aegir/config/nginx.conf /usr/local/etc/nginx/conf.d/aegir.conf

  printf "# Aegir time..\n########\n"
  printf "# Downloading provision..\n########\n"
  if [[ ${AEGIR7X} =~ ^(y|Y)$ ]]; then
    ${DRUSH} dl --package-handler=git_drupalorg --destination=/Users/${USERNAME}/.drush provision-7.x-3.x
  else
    ${DRUSH} dl --package-handler=git_drupalorg --destination=/Users/${USERNAME}/.drush provision-7.x-3.1
  fi
  printf "\n########\n# Clearing drush caches..\n########\n"
  ${DRUSH} cache-clear drush
  printf "\n########\n# Installing hostmaster..\n########\n"

  say "type the DB password you entered for my SQL earlier"
  if [[ ${AEGIR7X} =~ ^(y|Y)$ ]]; then
    ${DRUSH} hostmaster-install --aegir_root='/var/aegir' --root='/var/aegir/hostmaster-7.x-3.x' --http_service_type=nginx --aegir_host=aegir.ld --working-copy --client_email=${EMAIL} aegir.ld #remove this line when/if expects block below is enabled again.
  else
    ${DRUSH} hostmaster-install --aegir_root='/var/aegir' --root='/var/aegir/hostmaster-7.x-3.1' --http_service_type=nginx --aegir_host=aegir.ld --working-copy --client_email=${EMAIL} aegir.ld #remove this line when/if expects block below is enabled again.
  fi

  # This expect block works but the previous expect block doesn't so can't use this yet.
  # expect -c "
  #   drush hostmaster-install --aegir_root='/var/aegir' --root='/var/aegir/hostmaster-7.x-3.1' --http_service_type=nginx --aegir_host=aegir.ld  --client_email=$email aegir.ld
  #   expect \") password:\"
  #   send \"mysql\r\"
  #   expect \"Do you really want to proceed with the install (y/n):\"
  #   send \"y\r\"
  #   expect eof"

  if [[ $(wget http://aegir.ld > /dev/null 2>&1 | egrep "HTTP" | awk {'print $6'}) != "404" ]] ; then
    rm index.html > /dev/null 2>&1
    # printf "\n########\n# Changing some hostmaster varibles to defaults we like..\n########\n"
    # drush @hostmaster vset hosting_feature_platform_pathauto 1
    # drush @hostmaster vset hosting_feature_cron 0
    # drush @hostmaster vset "hosting_feature_Cron queue" 0
    # drush @hostmaster vset "hosting_feature_Hosting queue daemon" 1
    # drush @hostmaster vset hosting_feature_queued 1
    # drush @hostmaster vset hosting_queue_tasks_enabled 0
    # drush @hostmaster vset hosting_require_disable_before_delete 0

    printf "\n########\n# Download and start hosting queue daemon launch agent..\n########\n"
    curl https://gist.githubusercontent.com/BrianGilbert/9226172/raw/509f69711a5a2c61ec41b6d3b690a72096b26703/org.aegir.hosting.queued.plist > ~/Library/LaunchAgents/org.aegir.hosting.queued.plist
    launchctl load -w ~/Library/LaunchAgents/org.aegir.hosting.queued.plist

    curl https://gist.githubusercontent.com/BrianGilbert/9282670/raw/b5125abb144f683e75ea68696f8bf606b1631d07/nginx_xhprof.ld.conf > /var/aegir/config/server_master/nginx/pre.d/nginx_xhprof.ld.conf

    printf "\n########\n# Installing registry_rebuild drush module\n########\n"
    drush dl registry_rebuild

    printf "\n########\n# Symlinking platforms to ~/Sites/Aegir..\n########\n"
    mkdir -p ~/Sites/Aegir
    rmdir /var/aegir/platforms
    ln -s ~/Sites/Aegir /var/aegir/platforms

    printf "\n########\n# Enabling SSL for local sites..\n########\n"
    mkdir -p /usr/local/etc/ssl/private;
    openssl req -x509 -nodes -days 7300 -subj "/C=US/ST=New York/O=Aegir/OU=Cloud/L=New York/CN=*.aegir.ld" -newkey rsa:2048 -keyout /usr/local/etc/ssl/private/nginx-wild-ssl.key -out /usr/local/etc/ssl/private/nginx-wild-ssl.crt -batch 2> /dev/null;
    curl https://gist.githubusercontent.com/BrianGilbert/7760457/raw/267e582f7f5f7f87f194f508c745da353612e751/nginx_wild_ssl.conf > /var/aegir/config/server_master/nginx/pre.d/nginx_wild_ssl.conf;
    sudo /usr/local/bin/nginx -s reload;

    printf "# Setting known network interfaces to use 127.0.0.1 for DNS lookups,this may throw errors, that's ok...\n########\n"
    sudo networksetup -setdnsservers AirPort 127.0.0.1
    sudo networksetup -setdnsservers Ethernet 127.0.0.1
    sudo networksetup -setdnsservers 'Thunderbolt Ethernet' 127.0.0.1
    sudo networksetup -setdnsservers Wi-Fi 127.0.0.1

    say "Open your network settings to confirm DNS for your active network device is set to 127.0.0.1, or else things will not work properly"
    echo "
  ########
  # Open your network settings now and confirm the DNS for
  # your active device is set to 127.0.0.1, or else things
  # will not work properly later in the script.
  ########"

    printf "\n########\n# Saving some instructional notes to ~/Desktop/YourAegirSetup.txt..\n########\n"
    say "saving some instructional notes to your desktop"
    echo "Hi fellow Drupaler,

Here is some important information about your local Aegir setup.

Creating and maintaining this takes a lot of time, you can help:
  https://www.gittip.com/Brian%20Gilbert/

The date.timezone value is set to Melbourne/Australia you may want
to change it to something that suits you better.

Your Aegir sites are accesible using http and https, though you
will need to trust the certificate in your browser.

To change it, depending on what versions of php you installed,
type each of these in terminal and search for Melbourne:
 nano /usr/local/etc/php/5.3/php.ini
 nano /usr/local/etc/php/5.4/php.ini
 nano /usr/local/etc/php/5.5/php.ini
 nano /usr/local/etc/php/5.6/php.ini

Then restart nginx using:
 sudo /usr/local/bin/nginx -s reload

php53 is currently active, to switch the active version of php use
the following commands:
 go53
 go54
 go55
 go56

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
 /usr/local/etc/php/5.6/conf.d/ext-xdebug.ini

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
 $(brew --prefix solr)/example/multicore/core0/conf

You can run solr by executing the following in a terminal:
solr start -e multicore -p 8099

To stop solr:
solr stop -all

If things are not working after an OS update update then try the
following steps, reset DNS to 127.0.0.1 and run following command:
 sudo mkdir -p /var/log/aegir

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
    sleep 30;open http://rl.cm/OSXAegirDonation
  else
    echo "\n########\n# Something has gone wrong!\n# The aegir.ld site isn't accesible.\n# you'll probably need to rerun the installation.\n########\n"
  fi
} 2>&1 | tee -a ~/Desktop/aegir-install-logfile-$(date +"%Y-%m-%d.%H.%M.%S").log
echo "###fin###"
exit
