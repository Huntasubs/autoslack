```
 NAME:
        autoslack
 SYNTAX:
        /usr/bin/autoslack [OPTIONS] -i <packagename> ...
 OPTIONS:
        -h                      This helptext
        -v                      script version numer
        -c                      clean the package archive
        -g                      Just grab sources, don't build anything.
        -i <packagename>        install package. 
        -s <packagename>        find $packagename
        -u                      update SLACKBUILDS.TXT
        -f                      forces a rebuild of package and dependencies
        -m                      builds but does not install package
        -n                      attempt to install without grabbing dependencies
        -z                      skip md5check for source file. DANGEROUS
        -x                      force to read package information from
                                SLACKBUILDS.TXT
 OTHER:
                                the -i option needs to be the last one selected
```
---------------------------


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

--------------
historical 
--------------
I wrote this script after it became clear that I'd be installing slackware again, and I really *really* did not feel 
like recompiling a bunch of new packages. Again. The best thing I can say for this - it exists, I use it. 
In retrospect, there is probably a number of things that can be done with this code, but in reality, unless I personally
find a race condition, it probably isn't getting too much love. If you decide to use it (for some ungodly reason?) It should
work on all future versions of Slackware, provided you adjust the URL accordingly. 