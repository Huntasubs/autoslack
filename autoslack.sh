#!/bin/bash
#AutoSlack
#to install a package from slackbuilds just type at your prompt 
#>autoslack -i $PACKAGENAME 
#$PACKAGENAME can be in any case whatsover, since this does do
#some rudimentary fuzzy matching. This also resolves dependencies
#the "Unix way". (Not really, it's just terrible coding, and potentially
#has the possibility of spawning infinite autoslacks. Autoslack fhtagn!

SCRIPTVERSION="1.01"
SLAURL="rsync://slackbuilds.org/slackbuilds/14.1/SLACKBUILDS.TXT"
URPREFIX="rsync://slackbuilds.org/slackbuilds/14.1"
BUILDPREFIX="/tmp"
SLACKBUILDS=/usr/share/autoslack/SLACKBUILDS.TXT
SLACKRCHIVE=/usr/share/autoslack/packages/
PARSESLACK=0



preprerun () {
    if [[ $PACKAGENAME =~ ^$ ]]; then	
	echo "You did not select any packages to install, exiting" 
	exit 0
    else
	echo "installing $PACKAGENAME"
	#as an attempt to fix this freaking case issue.
	PACKAGENAME=$(grep -iFx "SLACKBUILD NAME: $PACKAGENAME" $SLACKBUILDS | sed 's/SLACKBUILD NAME: //g')
	if [[ $PACKAGENAME =~ ^$ ]]; then
	    echo "Something went wrong, package not found"
	    echo "Try to autoslack -s \$packagename"
	    exit 0
	fi	
	echo $PACKAGENAME
	logfile=$(echo $PACKAGENAME-`date +%d_%m_%y`.log)
    fi
}

grabslackbuild () {
    URSUFFIX=$(grep -iFx "SLACKBUILD NAME: $PACKAGENAME" $SLACKBUILDS -A 4 | grep "SLACKBUILD LOCATION:" |sed 's/SLACKBUILD LOCATION: .//g')
    rsync -v $URPREFIX/$URSUFFIX $BUILDPREFIX -r
}


helptext () {
    echo ""
    echo " NAME:"
    echo "	autoslack"
    echo " SYNTAX:"
    echo "	$0 [OPTIONS] -i <PACKAGENAME> ..."
    echo " OPTIONS:"
    echo "	-h 			This helptext"
    echo "	-v			script version numer"
    echo "	-c			clean the package archive"
    echo "	-g			Just grab sources, don't build anything."
    echo "	-i <packagename>	install package. "
    echo "	-s <packagename>	find \$packagename"
    echo "	-u			update SLACKBUILDS.TXT"
    echo "	-f			forces a rebuild of package and dependencies"
    echo "	-m			builds but does not install package"
    echo "	-n			attempt to install without grabbing dependencies"
    echo "	-z			skip md5check for source file. DANGEROUS"
    echo "	-x			force to read package information from"
    echo "				SLACKBUILDS.TXT"
    echo " OTHER:		"
    echo "				the -i option needs to be the last one selected"
}

noopts () {
    echo "You didn't specify any options"
    echo "Please run autoslack -h for assistance"
}
cleanarchive () {
    read -p "Are you sure you want to clean all of your old builds? yes/no " YESNO
    while true; do
	if [[ "$YESNO" = [yY]* ]]; then 
	    rm -v /usr/share/autoslack/packages/*
	    exit 0
	elif [[ "$YESNO" = [nN]* ]]; then
	    exit 0
	else
	    echo "I didn't catch that"
	    continue
	fi
    done
}

prerun () {
    if [ ! -d "/usr/share/autoslack/" ]; then
	mkdir "/usr/share/autoslack"
	mkdir "/usr/share/autoslack/packages"
    fi
    #let's make a logging directory
    if [ ! -d "/var/log/autoslack" ]; then
	mkdir /var/log/autoslack
    fi
    update
    if ((`grep $PACKAGENAME $SLACKBUILDS -c` >= 1)); then
	echo "available"
    else
	echo "no package called $PACKAGENAME found, exiting"
	exit 0
    fi
}

update () {
    rsync -v $SLAURL /usr/share/autoslack/
}

packagecheck () {
    if ((`ls /var/log/packages | grep $PACKAGENAME -c` >= 1)); then
	echo "-------------------------------------"
	echo "$PACKAGENAME or similar appears to be installed already."
	ls /var/log/packages | grep $PACKAGENAME
	echo "-------------------------------------"
	
	while true; do
	    read -p "do you want to rebuild / reinstall it? [yes/no] " YESNO
	    if [[ "$YESNO" = [yY]* ]]; then
		echo "Ok"
		break
	    elif [[ "$YESNO" = [nN]* ]]; then
		echo "not reinstalling"
		exit 0
	    else
		echo "I didn't catch that"
		continue
	    fi
	done
    fi
}

parsefromfile () {
    source $BUILDPREFIX/$PACKAGENAME/$PACKAGENAME.info
#    echo $DOWNLOAD
#    echo $MD5SUM
#    echo $DOWNLOAD_x86_64
#    echo $MD5SUM_x86_64
#    echo $REQUIRES
#    DEPS=$REQUIRES
#    echo $DEPS
#    exit 0
}

depcheck () {
    if [[ $PARSESLACK = 0 ]]; then
	parsefromfile
	DEPS=$REQUIRES
    else
	DEPS=$(grep -iFx "SLACKBUILD NAME: $PACKAGENAME" $SLACKBUILDS -A 8 | grep "REQUIRES" | sed 's/SLACKBUILD REQUIRES: //g' | sed 's/%README%//g' | sed 's/  / /g')
	fi
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
	    if [[ "$SKIPBUILD" = 1 ]]; then
		autoslack -j -i $i
	    else
		autoslack -i $i
	    fi
	done
    fi
}


arraychecking () {


    for x in ${URLARR[@]}; do
	filename=$(echo $x | sed 's/.*\///g')
	largefix=$(echo $BUILDPREFIX/$PACKAGENAME/$filename)
	y=(${MDARR[var]})
	echo $y	
	rm $BUILDPREFIX/$PACKAGENAME/$filename
	wget $x -P $BUILDPREFIX/$PACKAGENAME
	if [[ "$MDCHECK" != 1 ]]; then
	    #		#if [[ `md5sum $filename | sed "s/$filename//g"` = "28643857176697dc66786ee898089ca3" ]]; then
	    if [[ `md5sum $BUILDPREFIX/$PACKAGENAME/$filename | awk '{ print $1 }'` = `echo "$y" | sed 's/ //g'` ]]; then
		echo "yay"
		echo "------------got------------"
		md5sum $BUILDPREFIX/$PACKAGENAME/$filename 
		echo "----------expected---------"
		echo "$y"
		echo "---------------------------"
	    else
		echo "------------got------------"
		md5sum $BUILDPREFIX/$PACKAGENAME/$filename 
		echo "----------expected---------"
		echo "$y"
		echo "---------------------------"
		echo $MDARR
		echo "$package $filename does not pass md5 check. "
		echo "if you are sure about installing this,"
		echo "re-run autoslack with the -z option"
		exit 0
	    fi
	fi
	var=$((var+1))
    done
}

arraychecking2() {
    echo "ARRAYCHECK"
    #echo ${MDARR@}
    #echo ${urarr@}
  #  echo "ARRAYS"
   # echo $URLARR
   # echo $MDARR
   # echo $URLS
    var="0"
   # for x in ${URLARR[var]}
   # do
	#echo "$x"
	#echo "$var"
	#var=$((var+1))
	#echo $var
	#break
    #done
    for y in ${MDARR[var]}
    do
	echo $y
	echo ${URLARR[var]}
    done

    exit 0
}


curlgrab32 (){
    if [[ $PARSESLACK = 0 ]]; then
	parsefromfile
	URLS=$DOWNLOAD
	MDS=$MD5SUM
    else
	URLS=$(grep -iFx "SLACKBUILD NAME: $PACKAGENAME" $SLACKBUILDS -A 4 | grep DOWNLOAD | sed  's/SLACKBUILD DOWNLOAD: //g')
	MDS=$(grep -iFx "SLACKBUILD NAME: $PACKAGENAME" $SLACKBUILDS -A 6 | grep "SLACKBUILD MD5SUM" | sed 's/SLACKBUILD MD5SUM: //g')
    fi
    
    URLARR=(${URLS})
    MDARR=(${MDS})
    if [[ $URLARR = "UNSUPPORTED" ]];
    then
	while true; do
	    read -p "32bit not supported. Attempt to grab 64bit anyway? [yes/no] " YESNO
	    if [[ $YESNO = [yY]* ]]; then
		curlgrab64
		break
	    elif [[ $YESNO = [nN]* ]]; then
		 echo "not doing anything"
		 exit 0
	    else
		echo "I didn't catch that"
		continue
	    fi
	done
    else
	echo "" > /dev/null
    fi

	
}

curlgrab64 () {
    if [[ $PARSESLACK = 0 ]]; then
	parsefromfile
	URLS=$DOWNLOAD_x86_64
	MDS=$MD5SUM_x86_64
    else	
	URLS=$(grep -iFx "SLACKBUILD NAME: $PACKAGENAME" $SLACKBUILDS -A 5 | grep DOWNLOAD_x86_64 | sed  's/SLACKBUILD DOWNLOAD_x86_64: //g')
	MDS=$(grep -iFx "SLACKBUILD NAME: $PACKAGENAME" $SLACKBUILDS -A 7 | grep "SLACKBUILD MD5SUM_x86_64:" | sed 's/SLACKBUILD MD5SUM_x86_64: //g')
    fi
    URLARR=(${URLS})
    MDARR=(${MDS})

    if [[ $URLARR = "UNSUPPORTED" ]];
    then
	while true; do
	    read -p "64bit not supported. Attempt to grab 32bit anyway? [yes/no] " YESNO
	    if [[ $YESNO = [yY]* ]]; then
		curlgrab32
		break
	    elif [[ $YESNO = [nN]* ]]; then
		echo "not doing anything"
		exit 0
	    else
		echo "I didn't catch that"
		continue
	    fi
	done
	
    else
	echo "" > /dev/null
    fi

}

archcheck () {
    if [[ `uname -a | grep x86_64 -c` = 1 ]]; then
	#are there seperate sources for amd64?
	if [[ `grep -iFx "SLACKBUILD NAME: $PACKAGENAME" $SLACKBUILDS -A 5 | grep DOWNLOAD_x86_64 | sed  's/SLACKBUILD DOWNLOAD_x86_64: //g'` =~ ^$ ]];
	then
	    curlgrab32
	    arraychecking
	else
	    #if 64bit sources
	    curlgrab64
	    arraychecking
	fi
    else
	#we are not amd64, just grab the normal sources
	curlgrab32
    fi
}



findpackage () {
    grep -iFx "SLACKBUILD NAME: $PACKAGENAME" $SLACKBUILDS -A 8 | sed 's/SLACKBUILD //g' | grep -v LOCATION | grep -v DOWNLOAD | grep -v MD5SUM
    exit 0
}
installer () {
    #build and install
    #dumb hack to get around some bullshit, because slackbuilds don't enjoy being called remotely. Yay. 
    mypath=$(pwd)
    cd $BUILDPREFIX/$PACKAGENAME/
    sh *.SlackBuild >> /var/log/autoslack/$logfile
    cd $mypath
    #parse our log file for the installfile
    installpath=$(grep "Slackware package" /var/log/autoslack/$logfile | grep "created" | sed 's/created.//g' | sed 's/Slackware package //g')
    #install package
    if [[ $SKIPINSTALL = 1 ]]; then
	echo "Did not install"
	echo $installpath
	exit 0
    else
	installpkg $installpath
    fi
    #move the installer file to the slackarchive
    mv $installpath $SLACKRCHIVE
}


while getopts "fnjbhxzgmuvcys:i:r:" option
do 
    case $option in
	h ) helptext
	    exit 0
	    ;;
	v ) echo $SCRIPTVERSION
	    exit 0
	    ;;
	c ) cleanarchive
	    exit 0
	    ;;
	i ) PACKAGENAME=${OPTARG}
	    ;;
	u ) update
	    exit 0
	    ;;
	s ) PACKAGENAME=${OPTARG}
	    findpackage
	    exit 0
	    ;;
	f ) SKIPCHECK="1"
	    ;;
	g ) SKIPBUILD="1"
	    ;;
	n ) SKIPDEP="1"
	    ;;
	m ) SKIPINSTALL="1"
	    ;;
	z ) MDCHECK="1"
	    ;;
	x ) PARSESLACK=1
	    ;;
       	* ) noopts
	    exit 0
	    ;;
    esac
done



#hah, this was most of the script

prerun
preprerun
#update
grabslackbuild
parsefromfile
if [[ "$SKIPCHECK" = "1" ]]; then
    echo "" > /dev/null
else
    packagecheck
fi
if [[ "$SKIPDEP" = "1" ]]; then
    echo "" > /dev/null
else
    depcheck
fi
archcheck
if [[ "$SKIPBUILD" =~ "1" ]]; then
    echo "" > /dev/null
else	
    echo "INSTALLING"
    installer
fi

#go back to whence ye came
exit 0

