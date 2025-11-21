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
verbose="no"
skipUpdate="no"
ufwAlwaysOn="yes"
scoreonly="no"

. /etc/os-release
githubrepo=https://github.com/zonzorp/NETS1037
githubrepoURLprefix="$githubrepo"/raw/main
scriptdir="$(dirname $0)"
scriptname="$(basename $0)"

if [ "$(ip r s default |awk '{print $5}')" = "eth0" ]; then
  router=openwrt
  mgmt="-mgmt"
else
  router=pfsense
  mgmt=
fi

while [ $# -gt 0 ]; do
  case "$1" in
    -l | --lab)
      labnum="$2"
      shift
      ;;
    -s | --skipupdate)
      skipUpdate="yes" # this hidden options skips checking for script updates
      ;;
    -f | --skipufwtests)
      ufwAlwaysOn="no" # this hidden option allows not checking ufw rules for all services
      ;;
    -v | --verbose )
      verbose="yes"
      ;;
    -o | --scoreonly )
      skipUpdate="yes"
      scoreonly="yes"
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

# retrieve function libraries from github and source them
for script in nets1037-funcs.sh nets1037-grading-funcs.sh; do
  if [ ! -f "$scriptdir"/$script ]; then
    # echo "Retrieving $script from github"
    if ! wget -q -O "$scriptdir"/$script "$githubrepoURLprefix"/scripts/$script; then
       echo "You need $script from the course github repo in order to use this script." 1>&2
       echo "Automatic retrieval of the file has failed. Are you online?" 1>&2
       exit 1
    fi
  fi
  source "$scriptdir/$script"
done

# curl needed, install if necessary
curl-check || exit 1

############
# Main
############

# start a new logfile and start it with date/time info
date +"server-check running on %Y-%M-%D at %H:%M %p" >$logfile
echo "$0 $@" >>$logfile

#Checks if you can use sudo unless we are in scoreonly mode
[ "$scoreonly" = "yes" ] || sudo-check

# test if internet is reachable
ping -c 1 8.8.8.8 >&/dev/null
if [ $? -ne 0 ]; then
	problem-report "Not connected to the internet. This script requires a functional IPV4 internet connection."
	problem-report "Check that you are getting dhcp service on your first network interface (try 'ip a')."
	problem-report "Check that you have internet service on your host computer (try 'ping 8.8.8.8' in a command window on the host computer)"
	# leave the logfile in place for troubleshooting purposes
	exit 1
fi


if [ "$skipUpdate" = "no" ]; then
  verbose-report "Checking if script is up to date, please wait"
  for script in $scriptname nets1037-funcs.sh nets1037-grading-funcs.sh; do
    wget -nv -O "$scriptdir"/$script-new "$githubrepoURLprefix"/scripts/$script >& /dev/null
    diff "$scriptdir"/$script "$scriptdir"/$script-new >& /dev/null
    if [ "$?" != "0" -a -s "$scriptdir"/$script-new ]; then
      mv "$scriptdir"/$script-new "$scriptdir"/$script
      chmod +x "$scriptdir"/$script
      verbose-report "$scriptdir"/$script updated
      "$scriptdir"/$scriptname -s "$@"
      rm $logfile # this logfile is pointless, discard it
      exit
    else
      rm "$scriptdir"/$script-new
    fi
  done
fi

#cat <<EOF
#This script will check various parts of your server to see if you have completed
#the setup of the various services and configuration as instructed during the semester.
#***********************!!!!!!!!!!*********************
#It is expected that you use lower case only whenever you use your name as part of
#your server configuration, for username, domain name, etc.
#***********************!!!!!!!!!!*********************
#EOF

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
verbose-report "Host type: $hosttype"


# per lab checks now

if [[ $labnum =~ "1" ]]; then
  lab_header "01"
  if [ "`hostname`" != "nmshost" ]; then
    problem-report "Hostname is `hostname`, but this script is only valid on nmshost"
    problem-report "You need to log into nmshost to use this script"
    exit 2
  fi
  
  labscore=0
  labmaxscore=0

  if [ "$USER" != "$firstname" ]; then
    problem-report "You should be working from your own user account, not the student account or the root account"
    problem-report "Refer to the instructions for the lab to ensure you have created an account named $firstname"
    exit 3
  else
    ((labscore+=10))
  fi
  ((labmaxscore+=10))

  for host in pfsense loghost mailhost webhost proxyhost nmshost; do
    sshhost="$host$mgmt"
    [ "$host" = "pfsense" ] && remuser=admin@ || remuser=
    if ! ping -c 1 $sshhost >/dev/null; then
      problem-report "Unable to ping $sshhost"
      problem-report "Verify that $sshhost is up and can talk to the private network"
    else
      verbose-report "$sshhost responds to ping"
      ((labscore+=5))
    fi
    ((labmaxscore+=5))
    if ! ssh $remuser$sshhost true >/dev/null; then
      problem-report "Unable to access $remuser$sshhost"
      problem-report "Verify that $sshhost is up and providing ssh service"
    else
      verbose-report "$remuser$sshhost is accessible using ssh"
      ((labscore+=5))
    fi
    ((labmaxscore+=5))
    if ! ssh $remuser$sshhost -- ping -c 1 google.com >/dev/null; then
      problem-report "Unable to ping google.com from $remuser$sshhost"
      problem-report "Verify that $sshhost is up and can talk to the internet"
    else
      verbose-report "$remuser$sshhost can ping google.com"
      ((labscore+=5))
    fi
    ((labmaxscore+=5))
  done
  
  scores-report "Lab 01 score is $labscore out of $labmaxscore"
  score=$((score + labscore))
  maxscore=$((maxscore + labmaxscore))
  scores-report "   Running score is $score out of $maxscore"
#  scorespostdata="course=$course&semester=$semester&studentnumber=$studentnumber&firstname=$firstname&lastname=$lastname&lab=1&score=$labscore&maxscore=$labmaxscore"
#  curl -s -A "Mozilla/4.0" -d "$scorespostdata" $labscoresURL || problem-report "Unable to post scores to website"
fi

if [[ $labnum =~ "2" ]]; then
  lab_header "02"
  labscore=0
  labmaxscore=0
  case "$(hostname)" in
    # ensure we can reach loghost and then run the labcheck on it
    nmshost )
      if ! ping -c 1 loghost >/dev/null; then
        problem-report "Unable to ping loghost"
        problem-report "Verify that loghost is up and can talk to the private network"
      else
        verbose-report "loghost responds to ping"
      fi
      if ! ssh root@loghost true >/dev/null; then
        problem-report "Unable to access root on loghost"
        problem-report "Verify that loghost is up and providing ssh service and that on loghost you have copied the authorized_keys file from your ~/.ssh directory to the /root/.ssh directory"
      else
        verbose-report "loghost is accessible using ssh"
      fi
      # run check on loghost remotely

      sshhost="loghost$mgmt"
      scp -q "$scriptdir/$scriptname" "$scriptdir/nets1037-funcs.sh" "$scriptdir/nets1037-grading-funcs.sh" root@$sshhost:/root
      [ "$verbose" = "yes" ] && ssh root@$sshhost -- /root/"$scriptname" "$firstname" "$lastname" "$studentnumber" -l 2 -v -s
      read label loghostlabscore loghostlabmaxscore <<< "$(ssh root@$sshhost -- /root/$scriptname $firstname $lastname $studentnumber -l 2 -s -o)"
      if [ "$label" != "Scores:" ]; then
        problem-report "Remote run of lab checks on loghost failed to produce correct output: '$label $loghostlabscore $loghostlabmaxscore'"
      else
        labscore=$loghostlabscore
        labmaxscore=$loghostlabmaxscore
        scores-report "Lab 02 score from loghost is $labscore out of $labmaxscore"
      fi
      ;;
# loghost checks the db and logfiles for received logs and firewall rule
    loghost )
      package_checks mailutils mysql-server rsyslog-mysql
      which mysql >/dev/null && mysqlrecordcount="$(mysql -u root  <<< 'select count(*) from Syslog.SystemEvents;'|grep -v count)"
      if [ "$mysqlrecordcount" != "" ] && [ "$mysqlrecordcount" -gt 0 ]; then
        verbose-report "loghost mysql log database has logs in it"
        ((labscore+=10))
      else
        problem-report "loghost mysql log database is empty"
      fi
      ((labmaxscore+=10))
      if ss -tulpn |grep -q 'udp.*0.0.0.0:514.*0.0.0.0:.*syslogd' ; then
        verbose-report "loghost rsyslog is listening to the network on 514/udp"
        ((labscore+=10))
      else
        problem-report "loghost rsyslog is not listening to 514/udp for syslog on the network"
      fi
      ((labmaxscore+=10))
      if ufw status 2>&1 |grep '514/udp.*ALLOW'; then
        verbose-report "loghost ufw allows 514/udp"
        ((labscore+=5))
      else
        problem-report "loghost UFW is not allowing syslog traffic on 514/udp"
      fi
      ((labmaxscore+=5))
      # hostsinsyslog="$(awk '{print $2}' /var/log/syslog|sort|uniq -c)"
      # which mysql >/dev/null && hostsindb="$(mysql -u root <<< 'select distinct FromHost, count(*) from Syslog.SystemEvents group by FromHost;')"
      for host in loghost mailhost webhost proxyhost nmshost; do
        if awk '{print $2}' /var/log/syslog|grep -iq $host; then 
          verbose-report "loghost: logs from $host found in /var/log/syslog"
          ((labscore+=5))
        else
          problem-report "loghost: logs from $host not found in /var/log/syslog"
        fi
        ((labmaxscore+=5))
        if which mysql >/dev/null && [ "$(mysql -u root <<< 'select count(*) from Syslog.SystemEvents where FromHost like $host%;'|grep -v count)" -gt 0 ]; then
          verbose-report "loghost: logs from $host found in the mysql database"
          ((labscore+=5))
        else
          problem-report "loghost: logs from $host not found in the mysql database"
        fi
        ((labmaxscore+=5))
      done
      [ "$scoreonly" = "yes" ] && echo "Scores: $labscore $labmaxscore"
      exit
      ;;
  esac

  scores-report "Lab 02 score is $labscore out of $labmaxscore"
  score=$((score + labscore))
  maxscore=$((maxscore + labmaxscore))
  scores-report "   Running score is $score out of $maxscore"
#  scorespostdata="course=$course&semester=$semester&studentnumber=$studentnumber&firstname=$firstname&lastname=$lastname&lab=1&score=$labscore&maxscore=$labmaxscore"
#  curl -s -A "Mozilla/4.0" -d "$scorespostdata" $labscoresURL || problem-report "Unable to post scores to website"
fi

