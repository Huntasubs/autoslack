#!/bin/bash
##AutoSlack
##Type in the package name, it will go into slackbuilds.org 
##find the package for you
##download and install, so far with no dep resolution. Yay?




read -p "What package are you installing? " packagename

SLAURL="rsync://slackbuilds.org/slackbuilds/14.1/SLACKBUILDS.TXT"
URPREFIX="rsync://slackbuilds.org/slackbuilds/14.1"
PREFIX="/tmp"

#loop to check if stuff exists goes here
#for now this just rudely assumes that this is ok

mkdir /usr/share/autoslack
rsync -v $SLAURL /usr/share/autoslack

SLACKBUILDS=/usr/share/autoslack/SLACKBUILDS.TXT

URSUFFIX=$(grep -iFx "SLACKBUILD NAME: $packagename" $SLACKBUILDS -A 4 | grep "SLACKBUILD LOCATION:" |sed 's/SLACKBUILD LOCATION: .//g')


rsync $URPREFIX$URSUFFIX $PREFIX -r
wget $(grep -iFx "SLACKBUILD NAME: $packagename" $SLACKBUILDS -A 4 | grep DOWNLOAD | sed  's/SLACKBUILD DOWNLOAD: //g') -P $PREFIX/$packagename
cd $PREFIX/$packagename
sh *.SlackBuild > temp.txt
installpath=$(grep "Slackware package" temp.txt | grep "created" | sed 's/created.//g' | sed 's/Slackware package //g')
installpkg $installpath

