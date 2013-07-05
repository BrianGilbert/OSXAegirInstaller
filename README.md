OSXAegirInstaller
=================

This has been tested on 10.8.4, I expect it will work fine on 10.8.5 when that is released. 
It doesn't work on Mavericks 10.9 at this stage. I've submitted a bug report to apple and hope that it will be resolved by the time Mavericks is public

__Warning:__ I have tested this script extensivley on a clean install of OSX, but I take no responsability for anything that happens to your computer using the script.

It should be fine to install on any machine that doesn't have a webserver already running on port 80 or a DB server already running on 3306.

This script installs the following via Homebrew on OSX:
* wget
* gzip
* drush 6
* dnsmasq
* nginx
* mariadb
* php

And then installs Aegir 6.x-2.x branch

Once installed you can access the Aegir dashboard at http://aegir.ld
Any site you create that ends in .ld or has an alias ending in .ld will resolve to localhost and work within your browser.

Execute the following in terminal to run the installer:

    cd ~
    curl -O https://raw.github.com/BrianGilbert/OSXAegirInstaller/master/aegir.sh
    chmod +x aegir.sh
    sudo ./aegir.sh


This is the largest script I've written to date, so any improvements gladly accepted as pull requests!
