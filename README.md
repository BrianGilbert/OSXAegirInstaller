OSXAegirInstaller
=================

This has been tested on Mountain Lion 10.8.4 & Mavericks 10.9 DP5, I expect it will work fine on 10.8.5 when that is released.

__Warning:__ I have tested this script extensivley on a clean install of OSX, but I take no responsability for anything that happens to your computer using the script.

It should be fine to install on any machine that doesn't have a webserver already running on port 80 or a DB server already running on 3306.

This script installs the following via Homebrew on OSX:
* wget
* gzip
* drush 6
* dnsmasq
* nginx (with geoip and uploadprogress)
* mariadb
* php (with uploadprogress, xhprof and xdebug)
* solr4 (optional)

And then installs Aegir 6.x-2.x branch

Once installed you can access the Aegir dashboard at http://aegir.ld
Any site you create that ends in .ld or has an alias ending in .ld will resolve to localhost and work within your browser.

Execute the following in terminal to run the installer:

    cd ~
    curl -O https://raw.github.com/BrianGilbert/OSXAegirInstaller/master/aegir.sh
    chmod +x aegir.sh
    ./aegir.sh


This is the largest script I've written to date, so any improvements gladly accepted as pull requests!
