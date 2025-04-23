
# A function to do echo if the variable 'verbose' has the word 'yes' in it
# anything else on the command line is just used for the echo
function echoverbose {
    [ "$verbose" = "true" ] && echo "$@"
}

# This function will send an error message to stderr
# Usage:
#   error-message ["some text to print to stderr"]
#
function error-message {
  prog="$(basename "$0")"
  echo "${prog}: ${1:-Unknown Error - a moose bit my sister once...}" >&2
}

# This function will send a message to stderr and exit with a failure status
# Usage:
#   error-exit ["some text to print" [exit-status]]
#
function error-exit {
  error-message "$1"
  exit "${2:-1}"
}

# install incus if necessary, adding user to incus groups as needed
function incus-install-check {
	which incus >/dev/null && return
	if [ "$NAME" = "Ubuntu" ] && [ "$VERSION_ID" = "22.04" ]; then
		if [ ! -d /etc/apt/keyrings ]; then
		sudo mkdir -p /etc/apt/keyrings || error-exit "Could not begin to install incus by making keyrings directory"
		fi
		if [ ! -f /etc/apt/keyrings/zabbly.asc ]; then
			if sudo -- apt-get -qq update; then
				if ! sudo -- apt-get -qq install curl; then
					error-exit "Could not perform apt-get update, are we online?"
				fi
			fi
			sudo curl -fsSL https://pkgs.zabbly.com/key.asc -o /etc/apt/keyrings/zabbly.asc || error-exit "Couldn't add zabbly key to apt keyring"
		fi
		zabblysourcesfile=/etc/apt/sources.list.d/zabbly-incus-stable.sources
		zabblysourceslistcontent="$(cat <<EOF
Enabled: yes
Types: deb
URIs: https://pkgs.zabbly.com/incus/stable
Suites: $(. /etc/os-release && echo "${VERSION_CODENAME}")
Components: main                                       
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/zabbly.asc
EOF
)"
		if ! echo "$zabblysourceslistcontent" | cmp -s "$zabblysourcesfile"; then
			echo "$zabblysourceslistcontent" | sudo tee "$zabblysourcesfile" >/dev/null || error-exit "Unable to set zabbly repo sources file content for apt"
			sudo -- apt-get -qq update || error-exit "Unable to run apt update successfully"
		fi
	fi
	sudo -- apt-get -qq install incus >/dev/null || error-exit "Unable to install incus package"

# if incus was just installed, then we need to add ourselves to the new incus groups
# and rerun makecontainers using the new group perms
	incususer=${1:-$(id -un)}
	if [ $incususer != $(id -un) ]; then
		if sudo usermod -a -G incus,incus-admin "$incususer"; then
			echoverbose "
---------WARNING--------
User '$incususer' added to incus and incusadmin group.
Containers will be created using that account.
You will need to login to that account if you want to use the incus command to manage your containers after this script finishes.
------------------------
"
		fi
	elif ! id -Gn|grep -q incus-admin; then
		if sudo usermod -a -G incus,incus-admin "$(id -un)"; then
			echoverbose "
User '$(id -un)' added to incus and incusadmin groups.
In order to use this new permission, a new login shell is needed.
If you want to manage your containers using the incus command after this script finishes, you must fully logout.
Ubuntu GUI logout doesn't logout, 'pkill systemd' or a reboot is required to actually logout.
Continuing container creation now.
"
		fi
	fi
	sudo apt-get install -qq incus-ui-canonical >/dev/null || error-exit "Unable to install incus-ui-canonical package"
	sudo incus config set core.https_address :8443
}

# This function deletes existing lab incus containers
function delete-incus-containers {
  which incus >&/dev/null || return

  echoverbose "Deleting all existing containers"
  for target in $(incus list -c n -f csv); do
    incus delete "$target" --force
  done
  
  echoverbose "Deleting lan and mgmt networks"
  incus network delete lan 2>/dev/null
  incus network delete mgmt 2>/dev/null
}

function sudo-check {
  echoverbose "Checking for sudo"
  if [ "$(id -u)" -eq 0 ]; then
    error-message "Do not run this script using sudo, it will use sudo when it needs to"
  fi
  sudo true && echoverbose "sudo access ok" || return 1
}

# function to check for valid ip address
# expects a string to test in $1
function valid-ip {
  fmt="^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
  [[ "$1" =~ $fmt ]] && return || return 1
}

# function to check for and install puppetserver if necessary
function puppetserver-install {
  if ! systemctl is-active --quiet puppetserver 2>/dev/null; then
    if [ ! -f ~/Downloads/puppet8-release-focal.deb ]; then
      wget -q -O ~/Downloads/puppet8-release-focal.deb https://apt.puppet.com/puppet8-release-focal.deb
      if [ ! -f ~/Downloads/puppet8-release-focal.deb ]; then
        error-message "Failed to download puppet8 focal apt setup"
        return 1
      fi
    fi
    if ! sudo DEBIAN_FRONTEND=noninteractive dpkg -i ~/Downloads/puppet8-release-focal.deb; then
      error-message "Failed to dpkg install puppet8-release-focal.deb"
      return 1
    fi
    if ! sudo apt-get -qq update; then
      error-message "Failed apt update"
      return 1
    fi
    if ! sudo NEEDRESTART_MODE=a apt-get -y install puppetserver >/dev/null; then
      error-message "Failed to apt install puppetserver"
      return 1
    fi
    if ! sudo systemctl start puppetserver; then
      error-message "Failed to start puppetserver"
      return 1
    fi
    if ! sudo grep -q 'PATH=$PATH:/opt/puppetlabs/bin' /root/.bashrc; then
      sudo sed -i '$aPATH=$PATH:/opt/puppetlabs/bin' /root/.bashrc
    fi
  fi
}

function bolt-install {
  if ! which bolt >/dev/null; then
    echoverbose "Installing bolt"
    if [ ! -f ~/Downloads/puppet-tools-release-"$VERSION_CODENAME".deb ]; then
      wget -q -O ~/Downloads/puppet-tools-release-"$VERSION_CODENAME".deb https://apt.puppet.com/puppet-tools-release-"$VERSION_CODENAME".deb
      if [ ! -f ~/Downloads/puppet-tools-release-"$VERSION_CODENAME".deb ]; then
        error-message "Failed to download bolt apt setup"
        return 1
      fi
    fi
    if ! sudo DEBIAN_FRONTEND=noninteractive dpkg -i ~/Downloads/puppet-tools-release-"$VERSION_CODENAME".deb; then
      error-message "Failed to install puppet-tools-release-$VERSION_CODENAME.deb"
      return 1
    fi
    if ! sudo apt-get -qq update; then
      error-message "Failed to apt update"
      return 1
    fi
    if ! sudo NEEDRESTART_MODE=a apt-get -y install puppet-bolt >/dev/null; then
      error-message "Failed to install puppet-bolt"
      return 1
    fi
  fi
  echoverbose "Setting bolt defaults for $(whoami) to access via ssh:remoteadmin@${prefix}N-mgmt"
  if [ ! -f ~/.puppetlabs/etc/bolt/bolt-defaults.yaml ]; then
    [ -d ~/.puppetlabs/etc/bolt ] || mkdir -p ~/.puppetlabs/etc/bolt
    cat >~/.puppetlabs/etc/bolt/bolt-defaults.yaml <<EOF
inventory-config:
  ssh:
    user: remoteadmin
    host-key-check: false
    private-key: ~/.ssh/id_ed25519
EOF
  fi
  if [ -d /opt/puppetlabs/bin ]; then
    PATH="$PATH:/opt/puppetlabs/bin"
    # shellcheck disable=SC2016
    grep -q 'PATH=$PATH:/opt/puppetlabs/bin' ~/.bashrc || echo 'PATH=$PATH:/opt/puppetlabs/bin' >> ~/.bashrc
  fi
}

function puppet-lab {
  puppetserver-install || return 1
  echoverbose "Ensuring ${prefix}1 apache2 install manifests are present"
  puppetmanifestsdir=/etc/puppetlabs/code/environments/production/manifests
  puppetinitfile="$puppetmanifestsdir/init.pp"
  puppetsitefile="$puppetmanifestsdir/site.pp"
  sudo chgrp student "$puppetmanifestsdir"
  sudo chmod g+w "$puppetmanifestsdir"
  [ -f "$puppetinitfile" ] || cat > "$puppetinitfile" <<EOF
class webserver {
  package { 'apache2': ensure => 'latest', }
  service { 'apache2':
    ensure => 'running',
    enable => true,
    require => Package['apache2'],
  }
}
class logserver {
  package { 'rsyslog': ensure => 'latest', }
  package { 'logwatch': ensure => 'latest', }
  service { 'rsyslog':
    ensure => 'running',
    enable => true,
    require => Package['rsyslog'],
  }
}
class linuxextras {
  package { 'sl' : ensure => "latest", }
  \$mypackages = [ "cowsay", "fortune", "shellcheck", ]
  package { \$mypackages : ensure => "latest", }
}
class hostips {
    host { 'hostvm' : ip => "${lannetnum}.1",}
    host { 'hostvm-mgmt' : ip => "${mgmtnetnum}.1", host_aliases => 'puppet'}
    host { 'openwrt' : ip => "${lannetnum}.2",}
    host { 'openwrt-mgmt' : ip => "${mgmtnetnum}.2", }
    host { '${prefix}1' : ip => "${lannetnum}.${startinghostnum}",}
    host { '${prefix}1-mgmt' : ip => "${mgmtnetnum}.${startinghostnum}",}
    host { '${prefix}2' : ip => "${lannetnum}.((${startinghostnum} + 1 ))",}
    host { '${prefix}2-mgmt' : ip => "${mgmtnetnum}.((${startinghostnum} + 1))",}
}
EOF
  [ -f "$puppetsitefile" ] || cat > "$puppetsitefile" <<EOF
node ${prefix}1.home.arpa {
    include webserver
    include linuxextras
    include hostips
}
node ${prefix}2.home.arpa {
    include logserver
    include linuxextras
    include hostips
}
node default {
    include linuxextras
}
EOF
  bolt-install
}

# create CA and build certs
function build-and-push-certs {
    keydir=/etc/ssl/private
    certdir=/etc/ssl/certs
    csrdir=/etc/ssl/csrs
    cakeyfile=$keydir/$server.key
    certfile=$certdir/$server.crt
    cacertfile=$certdir/ca.crt
    if [ ! -d $csrdir ]; then
	    echoverbose "Making csr directory"
	    sudo mkdir $csrdir
	 fi
    # CA first
    if [ ! -f $keyfile ]; then
	    echoverbose "Creating CA key"
	    sudo openssl genrsa -out $cakeyfile 4096
	fi
    if [ ! -f $cacertfile ]; then
		echoverbose "Creating CA certificate"
  		sudo openssl req -x509 -new -nodes -key $cakeyfile -sha256 -days 3650 -subj "/CN=NETS1037" -out $cacertfile
	fi
    for server in loghost mailhost webhost proxyhost vpnhost nmshost; do
        keyfile=$keydir/$server.key
        certfile=$certdir/$server.crt
        csrfile=$csrdir/$server.csr
        if [ ! -f $keyfile ]; then
		    echoverbose "Creating $server key"
	        sudo openssl genrsa -out $keyfile 2048
        fi
        if [ -f $keyfile -a ! -f $certfile ]; then
			echoverbose "Creating $server certificate"
	        sudo openssl req -new -key $keykeyfile -subj "/CN=$server-mgmt" -out $csrfile
	        sudo openssl x509 -req -in $csrfile -CA $cacertfile -CAkey $cakeyfile -CAcreateserial -out $certfile -days 365 -sha256
        fi
		echoverbose "Pushing CA cert and $server key and cert"
        incus file push $cacertfile $server$cacertfile
        incus file push $certfile $server$certfile
        sudo incus file push $keyfile $server$keyfile
    done
}

function filepush {
	# retrieve config files from github repo
	target="$1"
	configfile="$2"
 	services="$3"
	if [ -z "$target" -o -z "$configfile" ]; then
 		echoverbose "filepush error: target='$target' configfile='$configfile' services='$services'"
		return 1
	fi
   	filedir="$scriptdir/$target/$(dirname $configfile)"
  	[ ! -d "$filedir" ] && mkdir -p "$filedir"
	if [ ! -f "$scriptdir/$target/$configfile" ]; then
		echoverbose "Retrieving $container $configfile config file"
		if ! wget -q -O "$scriptdir/$target/$configfile" "$githubrepoURLprefix/$target/$configfile"; then
			cat <<EOF
You need the "$configfile" file from $githubrepo in order to use this script. Automatic retrieval of the file has failed. Are we online?
EOF
			return 1
		fi
	fi
	# push config files to container, restarting services as needed
	echoverbose "Pushing $configfile to $target"
	if ! incus file push "$scriptdir/$target/$configfile" "$target/$configfile"; then
		echoverbose "incus file push failed"
  		return 1
	fi
 	if [ "$services" != "" ]; then
		echoverbose "Restarting $services"
		if ! incus exec "$target" -- systemctl restart "$services"; then
  			echoverbose "Failed to restart $target $services"
	 		return 1
  		fi
	fi
}

function packageinstalls {
	target="$1"
 	shift
	for packagename in $@; do
		echoverbose "Installing $packagename on $target"
		if ! incus exec "$container" -- apt-get -qq install "$packagename"; then
  			echoverbose "Failed to install $packagename on $target"
	 		return 1
		fi
	done
}
