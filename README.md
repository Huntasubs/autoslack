# autoslack
Autoslack is a script for automatically pulling down and building SlackbBuilds from http://slackbuilds.org.
It features (relatively rudimentary) dependency checking and resolution, and is somewhat inspired by FreeBSD's ports 
system. However, unlike FreeBSD ports, it relies on SLACKBUILDS.TXT as its package database, which it attempts to 
keep fresh using rsync. 
It is primarily targeted at compiling things for machines with AMD64 kernels, can fall back to i386, and has yet to 
be tested on an ARM system. 
Currently it's hardcoded to use the 14.1 SlackBuild tree, but is in practice used on a Slackware-Current box. 

--------------
requirements
--------------

bash
wget
rsync
grep 
sed

--------------
installing
--------------
This script can probably be run from everywhere you like, but really wants a symlink to autoslack 
in your $PATH somewhere. 

