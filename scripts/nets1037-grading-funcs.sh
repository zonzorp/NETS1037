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
course="COMP1071"
case `date +%m` in
01|02|03|04) semester="W`date +%y`";;
05|06|07|08) semester="S`date +%y`";;
09|10|11|12) semester="F`date +%y`";;
esac
skipUpdate="no"
ufwAlwaysOn="yes"
. /etc/os-release

############
# Functions
############

function usage {
	echo "$0 [-v] [-l|--lab labnumber(s)] [firstname lastname studentnumber]"
}

function problem-report {
	tee -a $logfile <<< ">>> Problem found: $1"
}

function verbose-report {
	[ "$verbose" = "yes" ] && echo "$1"
	echo "$1" >> $logfile
}

function scores-report {
	tee -a $logfile <<< "$1"
}

# function to print out header for output report section
# Usage: lab_header lab-name
function lab_header {
	echo ""
	echo "Checking for Lab $1 tasks"
	echo "--------------------------"
}

# function to check if packages are installed
# Usage: package_checks space-delimited-package-names
function package_checks {
	verbose-report ""
	verbose-report "Package install check"
	verbose-report "---------------------"
	final_status=0
	for pkgname in $1; do
		dpkg -L $pkgname >& /dev/null
		if [ $? != "0" ]; then
			final_status=$?
			problem-report "$pkgname package not installed"
			problem-report "Use apt-get to install the package"
		else
			verbose-report "$pkgname package found ok"
			((labscore++))
		fi
		((labmaxscore++))
	done
	return $final_status
}

function check_config_file {
	configfile="$1"
	directive="$2"
	value="$3"
	grep -q "$directive[ 	][ 	]*$value" $configfile
	if [ $? != "0" ]; then
		problem-report "$directive should be $value in $configfile"
	else
		verbose-report "$directive in $configfile ok"
		((labscore+=1))
	fi
	((labmaxscore+=1))
}

function check_config_file_allow_extra_stuff {
	configfile="$1"
	directive="$2"
	value="$3"
	grep -q "$directive[ 	].*$value.*" $configfile
	if [ $? != "0" ]; then
		problem-report "$directive should be $value in $configfile"
	else
		verbose-report "$directive in $configfile probably ok"
		((labscore+=1))
	fi
	((labmaxscore+=1))
}

function check_interface_config {
	ifacename="$1"
	ifaceaddr="$2"
	if [[ "${addrs[$ifacename]}" =~ "$ifaceaddr" ]]; then
		verbose-report "$ifacename/$ifaceaddr configured ok"
		((labscore+=3))
	else
		problem-report "$ifacename should be configured for address $ifaceaddr"
		if [[ "$VERSION_ID" < "18.04" ]]; then
			problem-report "Check your interfaces files"
		else
			problem-report "Check your netplan files"
		fi
	fi
	((labmaxscore+=3))
}

function check_ufw {
	service="$1"
	port="$2"
	if [ "$ufwAlwaysOn" = "yes" ]; then
		ufw status verbose |& grep "^$port " >/dev/null
		if [ $? != "0" ]; then
			problem-report "Firewall rule for $service missing"
			problem-report "Review the instructions for setting up a $service allow rule for ufw"
		else
			verbose-report "Firewall config for $service ok"
			((labscore+=2))
		fi
		((labmaxscore+=2))
	fi
}
