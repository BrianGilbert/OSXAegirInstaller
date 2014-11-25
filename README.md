OSXAegirInstaller
=================

This script does everything that you need for Aegir to run natively on your Mac that is running Yosemite, If you are using an older version of OSX you will need to upgrade first.

Install time ranges from 25 minutes for a single version of PHP up to 1 hour if you select all versions of PHP and ApacheSOLR. This is due to the fact most components are compiled specifically for your system.

When I started on this script it was not possible to install Aegir on a Mac at all. Its taken a lot of time to get this script as reliable as it now is, it would be great to show your appreciation for the time I've saved you with a [Paypal Donation](https://www.paypal.com/webscr?cmd=_donations&business=brian@briangilbert.net&item_name=OSXAegir%20Donation&currency_code=USD).

Prerequisites
-----------------
*A gmail address/password you can use for relaying emails

What get's installed?
---------------------------
This script installs/configures everything you need for Aegir to work on OSX, mostly via Homebrew:
* wget
* gzip
* drush 6 or 7
* dnsmasq
* nginx (with geoip and uploadprogress)
* mariadb
* php 5.3/5.4/5.5 (with uploadprogress, xhprof and xdebug)
* solr4 (optional)

And then installs Aegir 6.x-2.0 stable or Aegir 7.x-3.x

Once installed you can access the Aegir dashboard at [http://aegir.ld](http://aegir.ld)
Any site you create should ends in .ld or have an alias ending in .ld so that it will resolve to localhost and work within your browser.

The script creates unsigned SSL certificates so that you can access any of the sites you create using https.

Installation Instructions
------------------------------
Always check the current status first: https://github.com/BrianGilbert/OSXAegirInstaller/issues/25

* This only shows the known status
* Status is based on my ability to confirm any reports the script is not working, where due to an upstream issue I am unable to fix it myself

Execute the following in terminal to run the installer:

    cd ~
    curl -O https://raw.githubusercontent.com/BrianGilbert/OSXAegirInstaller/master/aegir.sh
    chmod +x aegir.sh
    ./aegir.sh

Post Install
---------------
After installation change php versions (and restart nginx) by running the following commands:

    go53
    go54
    go54

Uninstall
-----------
If the install fails or you don't like Aegir, you can re-run the script to uninstall everything.

Warning
-----------
I have tested this script extensivley on a clean install of OSX, but I take no responsability for anything that happens to your computer using the script.
I'd recommend you use Disk Utility to repair permissions on your primary drive before running this script. If you already have Drush installed you should remove it first so the script can install it.

It should be fine to install on any machine that doesn't have a webserver already running on port 80 or a DB server already running on 3306, this means that you can have MAMP or Acquia Dev Desktop installed as well as Aegir (unless you have changed the default ports on either of these to 80/3306).

Any improvements gladly accepted as pull requests!

Donations
-------------
It took around 3 months hacking and a patch to the Aegir project to actually make Aegir installable on a mac and then approximately 2 weeks to write the initial version of this script. Since them many changes have been made to make installation much more reliable, it would be great to show your appreciation for the time I've saved you with a [Paypal Donation](https://www.paypal.com/webscr?cmd=_donations&business=brian@briangilbert.net&item_name=OSXAegir%20Donation&currency_code=USD).

