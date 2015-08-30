#!/bin/bash
##AutoSlack
##Type in the package name, 
##it will go into slackbuilds.org 
##find the package for you
##download and install, 
##with really stupid dep resolution that involves spawning another copy of this process. 
##So far I've only tested this with a package with one dependency. 

#read -p "What package are you installing? " packagename

packagename="$*"

if [[ "$packagename" =~ ^$ ]]; then
    echo "You don't want to install any packages?"
    exit 0
    else
    echo "attempting to install $packagename"
fi

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
#Stuff happens here
#if deps happen grep for 'em
DEPS=$(grep -iFx "SLACKBUILD NAME: $packagename" $SLACKBUILDS -A 8 | grep "REQUIRES" | sed 's/SLACKBUILD REQUIRES: //g')
#if Deps 1 or more then resolve deps


if [[ "$DEPS" =~ ^$ ]]; then
    echo "NO DEPENDENCIES, CONTINUE"
else
    echo "NEED DEPENDENCIES"
    #store deps in an array
deparr=($DEPS)
for i in "${deparr[@]}"
	do
		#haha, we just re-launch the entire process @_@, self-recursion YAY. 
		#this is going to need to change because obviously the path of the script
		#is going to be super-differnt. 
		#and is probably not going to be a sh, but rather a symlink for easiness'
		#sake. 
		cd /home/`ps -o user= $(ps -o ppid= $PPID)`/autoslack/
		bash autoslack $i
	done
fi


wget $(grep -iFx "SLACKBUILD NAME: $packagename" $SLACKBUILDS -A 4 | grep DOWNLOAD | sed  's/SLACKBUILD DOWNLOAD: //g') -P $PREFIX/$packagename
cd $PREFIX/$packagename
sh *.SlackBuild > temp.txt
installpath=$(grep "Slackware package" temp.txt | grep "created" | sed 's/created.//g' | sed 's/Slackware package //g')
installpkg $installpath
exit
