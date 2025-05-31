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
