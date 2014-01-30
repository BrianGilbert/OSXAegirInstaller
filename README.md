OSXAegirInstaller
=================

This has been tested on Mountain Lion 10.8.4 & Mavericks 10.9, I expect it will work fine on 10.8.5 as well.

__Warning:__ I have tested this script extensivley on a clean install of OSX, but I take no responsability for anything that happens to your computer using the script.
I'd reccomend you use Disk Utility to repair permissions on your primary drive before running this script.

It should be fine to install on any machine that doesn't have a webserver already running on port 80 or a DB server already running on 3306.

Requirements:
* XCode installed and run at least once

This script installs the following via Homebrew on OSX:
* wget
* gzip
* drush 6
* dnsmasq
* nginx (with geoip and uploadprogress)
* mariadb
* php (with uploadprogress, xhprof and xdebug)
* solr4 (optional)

And then installs Aegir 6.x-2.0 stable

Once installed you can access the Aegir dashboard at http://aegir.ld
Any site you create that ends in .ld or has an alias ending in .ld will resolve to localhost and work within your browser.

Execute the following in terminal to run the installer:

    cd ~
    curl -O https://raw.github.com/BrianGilbert/OSXAegirInstaller/master/aegir.sh
    chmod +x aegir.sh
    ./aegir.sh


__SSL Support:__ This is part of main script since Dec 3 2013, so you only need the commends below if you installed prior.

This will enable access to your aegir sites using https, you will need to trust the certificate in your browser though.

    cd ~
    curl -O https://raw.github.com/BrianGilbert/OSXAegirInstaller/master/enablessl.sh
    chmod +x enablessl.sh
    ./aegir.sh

After installation change php versions (and restart nginx) by running the following commands:
    go53
    go54
    go54

This is the largest script I've written to date, so any improvements gladly accepted as pull requests!
