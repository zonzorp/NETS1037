#!/bin/bash

#############
# defaults
#############

labnum="123456789"
firstname="$FIRSTNAME"
lastname="$LASTNAME"
studentnumber="$STUDENTNUMBER"
score=0
labscore=0
labmaxscore=0
maxscore=0
labscoresURL="https://zonzorp.net/gc/postlabscores.php"
datetime=$(date +"%Y-%m-%d@%H:%M:%S%p")
logfile="/tmp/sc$datetime$$.log"
course="NETS1037"
case `date +%m` in
01|02|03|04) semester="W`date +%y`";;
05|06|07|08) semester="S`date +%y`";;
09|10|11|12) semester="F`date +%y`";;
esac
skipUpdate="no"
ufwAlwaysOn="yes"
. /etc/os-release
scriptname="$(basename $0)"

if [ "`hostname`" != "nmshost" ]; then
  echo "Hostname is `hostname`, but this script is only valid on nmshost"
  echo "You need to log into nmshost to use this script"
  exit 2
fi

# add in functions that are helpful
githubrepo=https://github.com/zonzorp/NETS1037
githubrepoURLprefix="$githubrepo"/raw/main
scriptdir="$(dirname $0)"
for script in nets1037-funcs.sh nets1037-grading-funcs.sh; do
  if [ ! -f "$scriptdir"/nets1037-funcs.sh ]; then
    echo "Retrieving script library file"
    if ! wget -q -O "$scriptdir"/nets1037-funcs.sh "$githubrepoURLprefix"/scripts/nets1037-funcs.sh; then
       echo "You need nets1037-funcs.sh from the course github repo in order to use this script."
       echo "Automatic retrieval of the file has failed. Are you online?"
       exit 1
    fi
  fi
done
source "$scriptdir"/nets1037-funcs.sh
source "$scriptdir"/nets1037-grading-funcs.sh

# curl needed, install if necessary
curl-check || exit 1

############
# Main
############

# start a new logfile and start it with date/time info
date +"server-check running on %Y-%M-%D at %H:%M %p" >$logfile
echo "$0 $@" >>$logfile

#Checks if you can use sudo
sudo-check

# test if internet is reachable
ping -c 1 8.8.8.8 >&/dev/null
if [ $? -ne 0 ]; then
	problem-report "Not connected to the internet. This script requires a functional IPV4 internet connection."
	problem-report "Check that you are getting dhcp service on your first network interface (try 'ip a')."
	problem-report "Check that you have internet service on your host computer (try 'ping 8.8.8.8' in a command window on the host computer)"
	# leave the logfile in place for troubleshooting purposes
	exit 1
fi

verbose="no"
while [ $# -gt 0 ]; do
	case "$1" in
		-l | --lab)
			labnum="$2"
			shift
			;;
		-s )
			skipUpdate="yes" # this hidden options skips checking for script updates
			;;
		-f )
			ufwAlwaysOn="no" # this hidden option allows not checking ufw rules for all services
			;;
		-v )
			verbose="yes"
			;;
		*)
			if [ "$firstname" = "" ]; then
				firstname="$1"
			elif [ "$lastname" = "" ]; then
				lastname="$1"
			elif [ "$studentnumber" = "" ]; then
				studentnumber="$1"
			else
				usage
				rm $logfile # this logfile is pointless, discard it
				exit
			fi
			;;
	esac
	shift
done

if [ "$skipUpdate" = "no" ]; then
  echo "Checking if script is up to date, please wait"
  for script in $scriptname nets1037-funcs.sh nets1037-grading-funcs.sh; do
    wget -nv -O "$scriptdir"/$script-new "$githubrepoURLprefix"/scripts/$script >& /dev/null
    diff "$scriptdir"/$script "$scriptdir"/$script-new >& /dev/null
    if [ "$?" != "0" -a -s "$scriptdir"/$script-new ]; then
      mv "$scriptdir"/$script-new "$scriptdir"/$script
      chmod +x "$scriptdir"/$script
      echo "$scriptdir"/$script updated
      "$scriptdir"/$scriptname -s "$@"
      rm $logfile # this logfile is pointless, discard it
      exit
    else
      rm "$scriptdir"/$script-new
    fi
  done
fi

cat <<EOF
This script will check various parts of your server to see if you have completed
the setup of the various services and configuration as instructed during the semester.
***********************!!!!!!!!!!*********************
It is expected that you use lower case only whenever you use your name as part of
your server configuration, for username, domain name, etc.
***********************!!!!!!!!!!*********************
EOF

while [ "$firstname" = "" ]; do
	read -p "Your first name? " firstname
done
while [ "$lastname" = "" ]; do
	read -p "Your last name? " lastname
done
while [ "$studentnumber" = "" ]; do
	read -p "Your student number? " studentnumber
done

if [ $(wc -c <<< "$studentnumber") -eq 9 ]; then
	snum=`cut -c 4-8 <<< "$studentnumber"`
elif [ $(wc -c <<< "$studentnumber") -eq 10 ]; then
	snum=`cut -c 5-9 <<< "$studentnumber"`
elif [ $(wc -c <<< "$studentnumber") -eq 2 ]; then
        snum=""
else
	problem-report "Your student number should be either 8 digits or 9 digits long"
	# leave the logfile in place for troubleshooting
	exit
fi
firstname=`tr 'A-Z' 'a-z'<<<"$firstname"`
lastname=`tr 'A-Z' 'a-z'<<<"$lastname"`
mydomain="$lastname$snum"
arch=`arch`
if [ $arch = "armv6l" -o $arch = "armv7l" ]; then
	arch=armhf
	hosttype=pi
elif [ $arch = "i686" -o $arch = "i586" -o $arch = "x86_64" ]; then
	arch=amd64
	hosttype=pc
elif [ $arch = "armv8" -o $arch = "aarch64" ]; then
	hosttype=mac
fi
hostname="$hosttype$studentnumber"

# Display runtime info
verbose-report "Course/Semester: $course/$semester" 
verbose-report "First name: $firstname"
verbose-report "Last name : $lastname"
verbose-report "Student Number: $studentnumber"
verbose-report "Host name: $hostname"

if [[ $labnum =~ "1" ]]; then
  lab_header "01"
  labscore=0
  labmaxscore=0
  #package_checks "curl"
  if ! ping -c 1 pfsense >/dev/null; then
    problem-report "Unable to ping pfsense"
    problem-report "Verify that pfsense is up and can talk to the private network"
  else
    verbose-report "pfsense responds to ping"
    ((labscore++))
  fi
  ((labmaxscore++))
  host=pfsense
  if ! ssh admin@$host true >/dev/null; then
    problem-report "Unable to access $host"
    problem-report "Verify that $host is up and providing ssh service"
  else
    verbose-report "$host is accessible using ssh"
    ((labscore++))
  fi
  ((labmaxscore++))
  if ! ssh admin@$host -- ping -c 1 google.com >/dev/null; then
    problem-report "Unable to ping google.com from $host"
    problem-report "Verify that $host is up and can talk to the internet"
  else
    verbose-report "$host can ping google.com"
    ((labscore++))
  fi
  ((labmaxscore++))
  
  for host in loghost mailhost webhost proxyhost nmshost; do
    if ! ssh $host true >/dev/null; then
      problem-report "Unable to access $host"
      problem-report "Verify that $host is up and providing ssh service"
    else
      verbose-report "$host is accessible using ssh"
      ((labscore++))
    fi
    ((labmaxscore++))
    if ! ssh $host -- ping -c 1 google.com >/dev/null; then
      problem-report "Unable to ping google.com from $host"
      problem-report "Verify that $host is up and can talk to the internet"
    else
      verbose-report "$host can ping google.com"
      ((labscore++))
    fi
    ((labmaxscore++))
  done
  
  scores-report "Lab 01 score is $labscore out of $labmaxscore"
  score=$((score + labscore))
  maxscore=$((maxscore + labmaxscore))
  scores-report "   Running score is $score out of $maxscore"
  scorespostdata="course=$course&semester=$semester&studentnumber=$studentnumber&firstname=$firstname&lastname=$lastname&lab=1&score=$labscore&maxscore=$labmaxscore"
  curl -s -A "Mozilla/4.0" -d "$scorespostdata" $labscoresURL || problem-report "Unable to post scores to website"
fi

