#!/bin/sh
# Written by Brian Gilbert @BrianGilbert_ https://github.com/BrianGilbert
# of Realityloop @Realityloop http://realitylop.com/
# I'm by no means a bash scripter, please submit pull requests/issues for improvements. :)

# Set some variables for username installing aegir and the OS X version
USERNAME=${USER-$LOGNAME} #`ps -o user= $(ps -o ppid= $PPID)`
osx=`sw_vers -productVersion`

# set volume so say text can be heard
osascript -e "set Volume 5"

printf "########
# This script is designed to be run by the primary account
# it has not been tested on a multi user setup.
########
# You cannot use this script if you have macports installed
# so we will uninstall it automatically
########
# OS X's inbuilt apache uses port 80 we need to disable it due to a
# conflict with nginx, we'll disable it for you during install.
########\n"
say "This script is designed to be run by the primary account,
it has not been tested on a multi user setup..
You cannot use this script if you have macports installed,
so we will uninstall it automatically.
Mac OS inbuilt apache uses port 80, we'll disable apache so engine x can
run."

printf "# Attempting to uninstall macports..\n########\n"
say "Attempting to uninstall macports, you may need to enter your password"
sudo port -fp uninstall installed 2&>1 >/dev/null
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
    ~/.macports 2&>1 >/dev/null

printf "\n########\n# Logging install process to file on desktop in case anything\n# goes wrong during install, No passwords are logged..\n########\n"
say "Creating logfile on desktop in case anything goes wrong during the install, no passwords are logged"
{
  printf "\n########\n# Disabling OS X's inbuilt apache..\n########\n"
  say "Disabling OS X's inbuilt apache, this will error if it's already disabled"
  sudo launchctl unload -w /System/Library/LaunchDaemons/org.apache.httpd.plist

  # Make sure that the script wasn't run as root.
  if [ $USERNAME = "root" ] ; then
    printf "# This script should not be run as sudo or root. exiting.\n"
    say "This script should not be run as sudo or root. exiting."
    exit
  else
    #fresh installations of mac osx does not have /user/local, so we need to create it first in case it's not there.
    sudo mkdir -p /usr/local
    sudo chown -R $USERNAME:admin /usr/local
    chmod 775 /usr/local
  fi

  printf "\n########\n# Checking OS version..\n########\n"
  say "Checking OS version."
  if [ $osx = 10.8.4 -o $osx = 10.8.5 -o $osx = 10.9 ] ; then
    printf "# Your OS is new enough, so let's go!\n########\n"
    say "Your OS is new enough, so let's go!"
  fi

  # Check Aegir isn't already installed.
  if [ -e "/var/aegir/config/includes/global.inc" ] ; then
    printf "# You already have aegir installed..\n########\n"
    say "You already have a gir installed.."
    #exit # Remove this line when uninstall block below is fixed.
    # Possibly I'll allow reinstallations in the future..
    #
    printf "# Should I remove it and do a clean install? [Y/n]\n########\n"
    say "Should I remove it and do, a clean install?"
    read CLEAN

    if [[ $CLEAN =~ ^(y|Y)$ ]]; then
      printf "# There is no turning back..\n# This will uninstall aegir and all related homebrew compononets before running a clean install, are you sure? [Y/n]\n########\n"
      say "There is no turning back.. This will uninstall a gir and all related homebrew compononents including any existing databases before running a clean install, are you sure?"
      read FORSURE
      if [[ $FORSURE =~ ^(y|Y)$ ]]; then
        printf "\n########\n# Don't say I didn't warn you, cleaning everything before running clean install..\n########\n"
        say "Don't say I didn't warn you, cleaning everything before running clean install.."

        printf "# Stopping and deleting any services that are already installed..\n########\n"
        say "Stopping and deleting any services that are already installed.."
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
          rm ~/Library/LaunchAgents/homebrew.mxcl.mariadb.plist
        fi

        if [ -e "~/Library/LaunchAgents/homebrew-php.josegonzalez.php53.plist" ] ; then
          launchctl unload -w ~/Library/LaunchAgents/homebrew-php.josegonzalez.php53.plist
          rm ~/Library/LaunchAgents/homebrew-php.josegonzalez.php53.plist
        fi

        if [ -e "~/Library/LaunchAgents/homebrew-php.josegonzalez.php54.plist" ] ; then
          launchctl unload -w ~/Library/LaunchAgents/homebrew-php.josegonzalez.php54.plist
          rm ~/Library/LaunchAgents/homebrew-php.josegonzalez.php54.plist
        fi

        if [ -e "~/Library/LaunchAgents/homebrew-php.josegonzalez.php55.plist" ] ; then
          launchctl unload -w ~/Library/LaunchAgents/homebrew-php.josegonzalez.php55.plist
          rm ~/Library/LaunchAgents/homebrew-php.josegonzalez.php55.plist
        fi

        printf "# Uninstalling related brews..\n########\n"
        say "Uninstalling related brews."
        brew uninstall php53-geoip
        brew uninstall php53-imagick
        brew uninstall php53-mcrypt
        brew uninstall php53-uploadprogress
        brew uninstall php53-xdebug
        brew uninstall php53-xhprof
        brew uninstall php53
        rm /var/log/nginx/php53-fpm.log
        rm /usr/local/bin/go53

        brew uninstall php54-geoip
        brew uninstall php54-imagick
        brew uninstall php54-mcrypt
        brew uninstall php54-uploadprogress
        brew uninstall php54-xdebug
        brew uninstall php54-xhprof
        brew uninstall php54
        rm /var/log/nginx/php54-fpm.log
        rm /usr/local/bin/go54

        brew uninstall php55-geoip
        brew uninstall php55-imagick
        brew uninstall php55-mcrypt
        brew uninstall php55-uploadprogress
        brew uninstall php55-xdebug
        brew uninstall php55-xhprof
        brew uninstall php55
        rm /var/log/nginx/php55-fpm.log
        rm /usr/local/bin/go55

        rm -rf /usr/local/etc/php

        brew uninstall phpcs

        brew uninstall nginx
        rm -rf /usr/local/etc/nginx
        rm -rf /usr/local/var/run/nginx
        sudo rm /var/log/nginx/error.log

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
        say "Removing previous drush installation, this may error."
        brew uninstall drush
        brew uninstall gzip
        brew uninstall wget
        printf "# Removing related configurations..\n########\n"
        say "Removing related configurations."
        sudo launchctl unload /System/Library/LaunchDaemons/org.postfix.master.plist
        sudo rm /etc/postfix/sasl_passwd
        sudo rm /etc/postfix/main.cf
        sudo cp /etc/postfix/main.cf.orig /etc/postfix/main.cf
        rm ~/.forward

  			brew uninstall mariadb
        rm /usr/local/etc/my-drupal.cnf
        rm /usr/local/etc/my.cnf
        rm -rf /usr/local/etc/my.cnf.d
        sudo rm /etc/my.cnf
        rm -rf /usr/local/var/mysql

        rm ~/Desktop/YourAegirSetup.txt

        printf "# Removing Aegir folder..\n########\n"
        say "Removing A gir folder."
        sudo rm -rf /var/aegir

      else
        printf "# Exiting..\n########\n"
        say "Exiting."
        exit
      fi
    # else
    #   printf "# Should I attempt an upgrade? [Y/n]\n########\n"
    #   say "Should I remove it and do, a clean install?"
    #   read UPGRADE
    #   if [[ $UPGRADE =~ ^(y|Y)$ ]]; then
    #     say "Upgrade isn't implemented yet"
    #     exit
    #   else
    #     printf "# Exiting..\n########\n"
    #     say "Exiting."
    #     exit
    #   fi
    fi
  fi

  printf "# Checking if the Command Line Tools are installed..\n########\n"
  say "Checking if the Command Line Tools are installed."
  if type "/usr/bin/clang" > /dev/null 2>&1; then
    printf "# They're installed.\n########\n"
    say "They're installed."
  else
    if [ $osx = 10.9 -o $osx = 10.9.1] ; then
      printf "# Your using 10.9 so I'll just install them for you..\n########\n"
      say "Your using 10.9 so I'll just install them for you."
      xcode-select --install
    else
      printf "########\n# Nope. You need the Command Line tools installed before this script will work\n\n"
      printf "# You will need to install them via the Xcode Preferences/Downloads tab:\n"
      printf "#    http://itunes.apple.com/au/app/xcode/id497799835?mt=12\n\n"
      printf "# Continue the script after you've installed them.\n########\n"
      say "You will need to install the Command Line Tools before this script will work, You can install them now and come back to this terminal and press Y to continue"
      read CLT
      if ! [[ $CLT =~ ^(y|Y)$ ]]; then
        exit
      fi
    fi
  fi

  echo "# You will need the following information during this script:
# -a gmail account that is configured to allow remote smtp access
# -the password for the gmail account address
# -an email address to receive notifications from aegir
# -attention to what is being requested via the script
########
# Your hostname will be set to aegir.ld\n########"
  say "You dooo need to keep an eye on this script as input is required throughout"

  echo "# I can also setup ApacheSolr which is best used in conjunction with:
# https://drupal.org/project/search_api_solr
# Set up solr [Y/n]:
########"
  say "Should I install ApacheSolr?"
  read SOLR

  if [[ $SOLR =~ ^(y|Y)$ ]]; then
    echo "
########
# Do you want solr to run automatically on boot [Y/n]:
########"
  say "Do you want Solr to run on boot?"
    read SOLRBOOT
  fi

  echo "
########
# What address should aegirs email notifications get sent to? [enter your email address]:
########"
  say "This is the email that notifications from a gir will be sent to"
  read email

  echo "
########
# I'd like to set up postfix so you receive emails from Aegir
#
# !!! This has only been tested with gmail accounts !!!
#
# If you don't do it now you will need to configure mail sending yourself:
# http://rl.cm/13ujhJp
#
# Do you have a gmail account you can use? [Y/n]:
########"
  say "Do you have a gee mail address you can use to relay the messages?"
  read gmail
  if [[ $gmail =~ ^(y|Y)$ ]]; then
    printf "\n########\n# OK, I'll attempt to set up postfix..\n"
    echo "########
# Whats the full gmail address? (eg. aegir@gmail.com):
########"
  say "type your gee mail address in now"
    read gmailaddress
    echo "
########
# What is the account password?
########"
  say "type your gee mail password in now"
    read gmailpass

    #setup mail sending
    printf "\n########\n# No time like the present, lets set up postfix now..\n########\n"
    say "Setting up postfix"
    sudo launchctl unload /System/Library/LaunchDaemons/org.postfix.master.plist
    echo "smtp.gmail.com:587 $gmailaddress:$gmailpass"  | sudo tee -a  /etc/postfix/sasl_passwd 2&>1 >/dev/null
    sudo postmap /etc/postfix/sasl_passwd
    sudo cp /etc/postfix/main.cf /etc/postfix/main.cf.orig
    echo "
myhostname =" aegir.ld"

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
tls_random_source=dev:/dev/urandom" | sudo tee -a  /etc/postfix/main.cf 2&>1 >/dev/null
    echo  "$email" >> ~/.forward
    sudo launchctl load -w /System/Library/LaunchDaemons/org.postfix.master.plist
  else
    printf "\n# Mail sending from aegir won't actually work until you configure postfix properly..\n"
    printf "\n# See: http://realityloop.com/blog/2011/06/05/os-x-ditching-mamp-pro-part-2-gmail-email-relay\n"
    say "Mail sending won't actually work until you configure postfix properly"
  fi

  printf "# Checking if Homebrew is installed..\n########\n"
  say "Checking if Homebrew is installed.."
  if type "brew" > /dev/null 2>&1; then
    printf "\n########\n# Affirmative! Lets make sure everything is up to date..\n# Just so you know, this may throw a few warnings..\n########\n"
    say "It is, lets make sure everything is up to date, you may see some errors in the output, thats ok."
    export PATH=/usr/local/bin:/usr/local/sbin:$PATH
    brew prune
    brew update
    brew doctor
  else
    printf "# Nope! Installing Homebrew now..\n########\n"
    say "Installing homebrew now, you'll need to hit enter when prompted"
    ruby -e "$(curl -fsSL https://raw.github.com/mxcl/homebrew/go/install)"
    echo  'export PATH=/usr/local/bin:/usr/local/sbin:$PATH' >> ~/.bash_profile
    echo  'export PATH=/usr/local/bin:/usr/local/sbin:$PATH' >> ~/.zshrc
    export PATH=/usr/local/bin:/usr/local/sbin:$PATH
    brew doctor
  fi

  # Tap required kegs
  printf "\n########\n# Now we'll tap some extra kegs we need..\n########\n"
  brew tap homebrew/versions 2&>1 >/dev/null
  brew tap homebrew/dupes 2&>1 >/dev/null
  brew tap josegonzalez/homebrew-php 2&>1 >/dev/null

  # Install required formula's
  printf "# Installing required brew formulae..\n########\n"
  say "Installing required brew formulae."
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
  brew uninstall drush 2&>1 >/dev/null
  brew install drush
  printf "\n########\n# Installing dnsmasq..\n########\n"
  brew install dnsmasq
  printf "\n########\n# Configuring dnsmasq..\n########\n"
  mkdir -p /usr/local/etc

  # Configure dnsmasq
  say "Setting up wildcard DNS so that domains ending in dot ld will resolve to your local machine"
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

  printf "# Setting known network interfaces to use 127.0.0.1 for DNS lookups..\n########\n"
  say "Setting known network interfaces to use 127.0.0.1 for DNS lookups, this may throw errors, thats ok."
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
  say "Open your network settings now and confirm DNS for your active network device is set to 127.0.0.1, or else things will not work properly later in the script"
  printf "# Setting hostname to aegir.ld\n########\n"
  sudo scutil --set HostName aegir.ld

  # Start dnsmasq
  printf "# Copying dnsmasq launch daemon into place..\n########\n"
  sudo cp $(brew --prefix dnsmasq)/homebrew.mxcl.dnsmasq.plist /Library/LaunchDaemons
  printf "# Starting dnsmasq..\n########\n"
  sudo launchctl load -w /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist

  printf "\n########\n# Installing nginx..\n########\n"
  say "installing and configuring engine x"
  brew install pcre geoip
  brew install nginx --with-debug --with-flv --with-geoip --with-http_dav_module --with-mp4 --with-spdy --with-ssl --with-upload-progress
  printf "\n########\n# Configuring nginx..\n########\n"
  if [ -e "/usr/local/etc/nginx/nginx.conf" ] ; then
  mv /usr/local/etc/nginx/nginx.conf /usr/local/etc/nginx/nginx.conf.bak
  fi
  wget https://gist.githubusercontent.com/BrianGilbert/5908352/raw/26e5943ec52c1d43c867fc16c4960e291b17f7d2/nginx.conf > /usr/local/etc/nginx/nginx.conf
  sed -i '' 's/\[username\]/'$USERNAME'/' /usr/local/etc/nginx/nginx.conf

  say "You may be prompted for your password"
  sudo mkdir -p $(brew --prefix nginx)/logs
  sudo mkdir -p /var/log/nginx
  sudo ln -s $(brew --prefix nginx)/logs/error.log /var/log/nginx/error.log
  sudo mkdir -p /var/lib/nginx

  printf "\n########\n# Installing mariadb..\n########\n"
  say "installing and configuring maria db"
  brew install cmake
  brew install mariadb
  unset TMPDIR
  printf "\n########\n# Configuring mariadb..\n########\n"
  mysql_install_db --user=$USERNAME --basedir="$(brew --prefix mariadb)" --datadir=/usr/local/var/mysql --tmpdir=/tmp
  curl https://gist.github.com/BrianGilbert/6207328/raw/10e298624ede46e361359b78a1020c82ddb8b943/my-drupal.cnf > /usr/local/etc/my-drupal.cnf
  say "You may be prompted for your password"
  sudo ln -s /usr/local/etc/my-drupal.cnf /etc/my.cnf

  printf "\n########\n# Installing php54..\n########\n"
  say "installing and configuring php 5.4"
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

    say "You may be prompted for your password"#
  	sudo ln -s $(brew --prefix josegonzalez/php/php54)/var/log/php-fpm.log /var/log/nginx/php54-fpm.log

    mkdir -p ~/Library/LaunchAgents
    cp $(brew --prefix josegonzalez/php/php54)/homebrew-php.josegonzalez.php54.plist ~/Library/LaunchAgents/

  echo "#!/bin/sh
# Written by Brian Gilbert @BrianGilbert_ https://github.com/BrianGilbert
# of Realityloop @Realityloop http://realitylop.com/

# Remove old symlink for xhprof and create correct one for this version of php
rm /usr/local/opt/xhprof 2&>1 >/dev/null
ln -s  $(brew --prefix php54-xhprof) /usr/local/opt/xhprof

# Stop php-fpm and start correct version
launchctl unload -w ~/Library/LaunchAgents/homebrew-php.josegonzalez.php53.plist 2&>1 >/dev/null
launchctl unload -w ~/Library/LaunchAgents/homebrew-php.josegonzalez.php54.plist 2&>1 >/dev/null
launchctl unload -w ~/Library/LaunchAgents/homebrew-php.josegonzalez.php55.plist 2&>1 >/dev/null
launchctl load -w ~/Library/LaunchAgents/homebrew-php.josegonzalez.php54.plist

# Brew link correct php version
brew unlink php53
brew unlink php55
brew link php54

# Restart nginx
sudo /usr/local/bin/nginx -s reload" >> /usr/local/bin/go54
  chmod 755 /usr/local/bin/go54

  brew unlink php54

  printf "\n########\n# Installing php55..\n########\n"
  say "installing and configuring php 5.5"
  brew install php55 --without-apache --with-fpm --with-gmp --with-imap --with-mysql --with-homebrew-curl --with-homebrew-libxslt --with-homebrew-openssl
  brew install php55-geoip
  brew install php55-imagick
  brew install php55-mcrypt
  brew install php55-uploadprogress
  brew install php55-xdebug
  brew install php55-xhprof

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

    cp $(brew --prefix josegonzalez/php/php55)/homebrew-php.josegonzalez.php55.plist ~/Library/LaunchAgents/

  echo "#!/bin/sh
# Written by Brian Gilbert @BrianGilbert_ https://github.com/BrianGilbert
# of Realityloop @Realityloop http://realitylop.com/

# Remove old symlink for xhprof and create correct one for this version of php
rm /usr/local/opt/xhprof 2&>1 >/dev/null
ln -s  $(brew --prefix php55-xhprof) /usr/local/opt/xhprof

# Stop php-fpm and start correct version
launchctl unload -w ~/Library/LaunchAgents/homebrew-php.josegonzalez.php53.plist 2&>1 >/dev/null
launchctl unload -w ~/Library/LaunchAgents/homebrew-php.josegonzalez.php54.plist 2&>1 >/dev/null
launchctl unload -w ~/Library/LaunchAgents/homebrew-php.josegonzalez.php55.plist 2&>1 >/dev/null
launchctl load -w ~/Library/LaunchAgents/homebrew-php.josegonzalez.php55.plist

# Brew link correct php version
brew unlink php53
brew unlink php54
brew link php55

# Restart nginx
sudo /usr/local/bin/nginx -s reload" >> /usr/local/bin/go55
  chmod 755 /usr/local/bin/go55

  brew unlink php55

  printf "\n########\n# Installing php53..\n########\n"
  say "installing and configuring php 5.3"
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

    cp $(brew --prefix josegonzalez/php/php53)/homebrew-php.josegonzalez.php53.plist ~/Library/LaunchAgents/

  echo "#!/bin/sh
# Written by Brian Gilbert @BrianGilbert_ https://github.com/BrianGilbert
# of Realityloop @Realityloop http://realitylop.com/

# Remove old symlink for xhprof and create correct one for this version of php
rm /usr/local/opt/xhprof 2&>1 >/dev/null
ln -s  $(brew --prefix php53-xhprof) /usr/local/opt/xhprof

# Stop php-fpm and start correct version
launchctl unload -w ~/Library/LaunchAgents/homebrew-php.josegonzalez.php53.plist 2&>1 >/dev/null
launchctl unload -w ~/Library/LaunchAgents/homebrew-php.josegonzalez.php54.plist 2&>1 >/dev/null
launchctl unload -w ~/Library/LaunchAgents/homebrew-php.josegonzalez.php55.plist 2&>1 >/dev/null
launchctl load -w ~/Library/LaunchAgents/homebrew-php.josegonzalez.php53.plist

# Brew link correct php version
brew unlink php54
brew unlink php55
brew link php53

# Restart nginx
sudo /usr/local/bin/nginx -s reload" >> /usr/local/bin/go53
  chmod 755 /usr/local/bin/go53

  printf "\n########\n# Installing php code sniffer..\n########\n"
  say "installing and configuring php code sniffer"
  brew install drupal-code-sniffer

  #Solr
  if [[ $SOLR =~ ^(y|Y)$ ]]; then
  printf "\n########\n# Installing solr..\n########\n"
  say "installing solr"
  brew install solr
  mkdir -p ~/Library/LaunchAgents
  printf "\n########\n# Downloading solr launch daemon..\n########\n"
  curl https://gist.github.com/BrianGilbert/6208150/raw/dfe9d698aee2cdbe9eeae88437c5ec844774bdb4/com.apache.solr.plist > ~/Library/LaunchAgents/com.apache.solr.plist
  sed -i '' 's/\[username\]/'$USERNAME'/' ~/Library/LaunchAgents/com.apache.solr.plist
  fi

  printf "\n########\n# Setting up launch daemons..\n########\n"
  say "Setting up launch daemons, You may be prompted for your password"
  sudo cp $(brew --prefix nginx)/homebrew.mxcl.nginx.plist /Library/LaunchDaemons/
  sudo chown root:wheel /Library/LaunchDaemons/homebrew.mxcl.nginx.plist

  cp $(brew --prefix mariadb)/homebrew.mxcl.mariadb.plist ~/Library/LaunchAgents/


  printf "\n########\n# Launching daemons now..\n########\n"
  say "Launching daemons now"
  sudo launchctl load -w /Library/LaunchDaemons/homebrew.mxcl.nginx.plist
  launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.mariadb.plist
  launchctl unload -w ~/Library/LaunchAgents/homebrew-php.josegonzalez.php54.plist
  launchctl unload -w ~/Library/LaunchAgents/homebrew-php.josegonzalez.php55.plist
  launchctl load -w ~/Library/LaunchAgents/homebrew-php.josegonzalez.php53.plist
  if [[ $SOLRBOOT =~ ^(y|Y)$ ]]; then
    launchctl load -w ~/Library/LaunchAgents/com.apache.solr.plist
  fi

  printf "\n########\n# Finishing mariadb setup..\n########\n"
  say "Finishing Maria db setup"
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
  say "Enter the following when prompted. Current password: hit enter. Set root password: press Y, New password: type m y s q l, Remove anonymous users: press y, Disallow root login remotely: press y, Remove test database and access to it: press y, Reload privilege tables now: press y."

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

  printf "\n########\n# Doing some setup ready for Aegir install..\n########\n"
  say "preflight setup for a gir install"
  sudo mkdir -p /var/aegir
  sudo chown $USERNAME /var/aegir
  sudo chgrp staff /var/aegir
  sudo dscl . append /Groups/_www GroupMembership $USERNAME
  echo "$USERNAME ALL=NOPASSWD: /usr/local/bin/nginx" | sudo tee -a  /etc/sudoers
  ln -s /var/aegir/config/nginx.conf /usr/local/etc/nginx/aegir.conf

  printf "\n########\n# Adding aegir.conf include to ngix.conf..\n########\n"
  ed -s /usr/local/etc/nginx/nginx.conf <<< $'g/#aegir/s!!include /usr/local/etc/nginx/aegir.conf;!\nw'

  printf "\n########\n# Aegir time..\n########\n"
  printf "\n########\n# Downloading provision..\n########\n"
  DRUSH='drush --php=/usr/local/bin/php'
  $DRUSH dl --destination=/users/$USERNAME/.drush provision-6.x-2.0
  printf "\n########\n# Clearing drush caches..\n########\n"
  $DRUSH cache-clear drush
  printf "\n########\n# Installing hostmaster..\n########\n"

  say "type the DB password you entered "
  $DRUSH hostmaster-install --aegir_root='/var/aegir' --root='/var/aegir/hostmaster-6.x-2.0' --http_service_type=nginx --aegir_host=aegir.ld  --client_email=$email aegir.ld #remove this line when/if expects block below is enabled again.

  # This expect block works but the previous expect block doesn't so can't use this yet.
  # expect -c "
  #   drush hostmaster-install --aegir_root='/var/aegir' --root='/var/aegir/hostmaster-6.x-2.x-dev' --http_service_type=nginx --aegir_host=aegir.ld  --client_email=$email aegir.ld
  #   expect \") password:\"
  #   send \"mysql\r\"
  #   expect \"Do you really want to proceed with the install (y/n):\"
  #   send \"y\r\"
  #   expect eof"

  echo "###
### Custom site for xhprof.
###

server {
  include fastcgi_params;
  fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
  limit_conn    gulag 32; # like mod_evasive - this allows max 32 simultaneous connections from one IP address
  listen        *:80;
  server_name  xhprof.ld;
  root   /usr/local/opt/xhprof/xhprof_html/;

  # Extra configuration from modules:
  include       /var/aegir/config/includes/nginx_vhost_common.conf;
}
" >> /var/aegir/config/server_master/nginx/pre.d/nginx_xhprof.ld.conf

  printf "\n########\n# Grabbing registry_rebuild drush module\n########\n"
  say "install registry rebuild"
  drush dl registry_rebuild

  printf "\n########\n# Symlinking platforms to ~/Sites/Aegir..\n########\n"
  say "symbolic linking a gir platforms directory to your Sites slash Aegir directory"
  mkdir -p /Users/$USERNAME/Sites/Aegir
  rmdir /var/aegir/platforms
  ln -s /Users/$USERNAME/Sites/Aegir /var/aegir/platforms

  mkdir -p /usr/local/etc/ssl/private;
  openssl req -x509 -nodes -days 7300 -subj "/C=US/ST=New York/O=Aegir/OU=Cloud/L=New York/CN=*.aegir.ld" -newkey rsa:2048 -keyout /usr/local/etc/ssl/private/nginx-wild-ssl.key -out /usr/local/etc/ssl/private/nginx-wild-ssl.crt -batch 2> /dev/null;
  wget -O /var/aegir/config/server_master/nginx/pre.d/nginx_wild_ssl.conf https://gist.github.com/BrianGilbert/7760457/raw/fa9163ecc533ae14ea1332b38444e03be00dd329/nginx_wild_ssl.conf;
  sudo /usr/local/bin/nginx -s reload;

  printf "\n########\n# Saving some instructional notes to ~/Desktop/YourAegirSetup.txt..\n########\n"
  say "saving some instructional notes to your desktop"
  sudo sh -c 'echo "Hi fellow Drupaler,

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

After using this script please take the time to say thanks:
http://twitter.com/BrianGilbert_

1. https://drupal.org/project/barracuda
" >> ~/Desktop/YourAegirSetup.txt'

  printf "\n########\n# Attempting to email it to you as well..\n########\n"
  say "emailing it to you as well"
  mail -s 'Your local Aegir setup' $email < ~/Desktop/YourAegirSetup.txt

  printf "\n########\n# The date.timezone value in /usr/local/etc/php/[version]/php.ini\n# Is set to Melbourne/Australia\n# You may want to change it to something that suits you better.\n########\n"
  # printf "The mysql root password is set to 'mysql' and login is only possible from localhost..\n"
  printf "\n########\n# Double check your network interfaces to ensure their DNS server is set to 127.0.0.1 as we only tried to set commonly named interfaces.\n########\n"
  printf "\n########\n# Please say thanks @BrianGilbert_  http://twiter.com/BrianGilbert_\n########\n"
  say "please say thanks via twitter, at, Brian Gilbert underscore"
  printf "\n########\n# Creating and maintaining this takes a lot of time, please help:\n#  https://www.gittip.com/realityloop/\n########\n"
  say "Development and maintenance of this script takes a lot of time, if it makes life easier for you please support me with a donation"
  printf "\n########\n# Finished..\n########\n"
} 2>&1 | tee -a ~/Desktop/aegir-install-logfile$(date +"%Y-%m-%d.%H:%M:%S").log
sleep 5;open https://www.gittip.com/Brian%20Gilbert/
exit
