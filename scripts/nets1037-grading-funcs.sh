
############
# Functions
############

function usage {
	echo "$0 [-v] [-l|--lab labnumber(s)] [firstname lastname studentnumber]"
}

function problem-report {
  if [ "$scoreonly" = "no" ]; then
    tee -a $logfile <<< ">>> Problem found: $1"
  else
    echo >> $logfile <<< ">>> Problem found: $1"
  fi
}

function verbose-report {
  if [ "$verbose" = "yes" ]; then
    tee -a $logfile <<< "$1"
  else
    echo >> $logfile <<< "$1"
  fi
}

function scores-report {
  if [ "$scoreonly" = "no" ]; then
    tee -a $logfile <<< "$1"
  else
    echo >> $logfile <<< "$1"
  fi
}

# function to print out header for output report section
# Usage: lab_header lab-name
function lab_header {
	[ "$scoreonly" = "yes" ] && return
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

function curl-check {
  if ! which curl >/dev/null ; then
    if ! sudo apt-get -qq update; then
      problem-report "Unable to run apt-get update successfuly, are we online?"
      return 1
    fi
    if ! sudo apt-get -qq install curl; then
      problem-report "Unable to apt-get -qq install curl, is the disk full or the ubuntu repo having problems?"
      return 1
    fi
    verbose-report "curl installed"
  else
    verbose-report "curl found"
  fi
}
