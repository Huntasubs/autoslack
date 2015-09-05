#!/bin/bash
#AutoSlack
#to grab a package from slackbuilds just type at your prompt 
#>autoslack $packagename 
#$packagename can be in any case whatsover, since this does do
#some rudimentary fuzzy matching. This also resolves dependencies
#the "Unix way". (Not really, it's just terrible coding, and potentially
#has the possibility of spawning infinite autoslacks. Autoslack ftagn!

#read -p "What package are you installing? " packagename

ourpath=$(pwd)
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
SLACKRCHIVE=/usr/share/autoslack/packages/

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
		autoslack $i
	done
fi


#are we amd64?
if [[ `uname -a | grep x86_64 -c` = 1 ]]; then
	#are there seperate sources for amd64?
	if [[ `grep -iFx "SLACKBUILD NAME: $packagename" $SLACKBUILDS -A 5 | grep DOWNLOAD_x86_64 | sed  's/SLACKBUILD DOWNLOAD_x86_64: //g'` =~ ^$ ]];
		then
			#if not, grab normal sources
	        wget $(grep -iFx "SLACKBUILD NAME: $packagename" $SLACKBUILDS -A 4 | grep DOWNLOAD | sed  's/SLACKBUILD DOWNLOAD: //g') -P $PREFIX/$packagename
		else
			#if yes, grab regular sources
			wget $(grep -iFx "SLACKBUILD NAME: $packagename" $SLACKBUILDS -A 5 | grep DOWNLOAD_x86_64 | sed  's/SLACKBUILD DOWNLOAD_x86_64: //g') -P $PREFIX/$packagename
	fi
else
		#we are not amd64, just grab the normal sources
        wget $(grep -iFx "SLACKBUILD NAME: $packagename" $SLACKBUILDS -A 4 | grep DOWNLOAD | sed  's/SLACKBUILD DOWNLOAD: //g') -P $PREFIX/$packagename
fi


cd $PREFIX/$packagename
#a clumsy hack, but I oddly-enough, like to be able to read through this information
#Probably should be offloaded to a /var/log/ somewhere
sh *.SlackBuild > temp.txt
installpath=$(grep "Slackware package" temp.txt | grep "created" | sed 's/created.//g' | sed 's/Slackware package //g')
installpkg $installpath
mv $installpath $SLACKRCHIVE
cd $ourpath
exit

