OSXAegirInstaller
=================

This script installs aegir on OSX using Homebrew

At this point in time it has been tested on 10.8.4, I expect it will work fine on 10.8.5 when that is released.

It is known to not work on Mavericks 10.9 at this stage.

Execute the following in terminal to run the installer:
cd ~
curl -O https://raw.github.com/BrianGilbert/OSXAegirInstaller/master/aegir.sh
chmod +x aegir.sh
sudo ./aegir.sh

Warning: I have tested this script extensivley on a clean install of OSX, but I take no responsability for anything that happens to your computer using the script.
