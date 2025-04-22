#!/bin/bash
# This script creates a virtual network suitable for learning about networking
# created by dennis simpson 2023, all rights reserved

source /etc/os-release
githubrepo=https://github.com/zonzorp/NETS1037
githubrepoURLprefix="$githubrepo"/raw/main
scriptdir="$(dirname $0)"

if [ ! -f "$scriptdir"/nets1037-funcs.sh ]; then
   echo "Retrieving script library file"
   if ! wget -q -O "$scriptdir"/nets1037-funcs.sh "$githubrepoURLprefix"/nets1037-funcs.sh; then
     echo "You need nets1037-funcs.sh from the course github repo in order to use this script."
     echo "Automatic retrieval of the file has failed. Are you online?"
     exit 1
   fi
 fi
 source "$scriptdir"/nets1037-funcs.sh

lannetnum="192.168.16"
mgmtnetnum="172.16.1"
bridgeintf=incusbr0
lanintf=lan
mgmtintf=mgmt
prefix=server
nets1037=false
startinghostnum=241
remoteadmin="remoteadmin"
numcontainers=1
verbose=false

sudo-check

snap list lxd 2>/dev/null && error-exit "This script is not designed to run with lxd, use a VM which has never had any containers yet and snap remove lxd"

# save command for re-execution if necessary
commandline="$0 $@"

# allow choices on the command line
while [ $# -gt 0 ]; do
    case "$1" in
        --help | -h )
            echo "
Usage: $(basename "$0") [-h | --help] [--fresh] [--prefix targetnameprefix] [--user remoteadminaccountname] [--lannet A.B.C] [--mgmtnet A.B.C] [--count N] [--hostnumbase N] [--nets1037] [--bridgeintf ifname] [--mgmtintf ifname] [--lanintf ifname]
This script sets up a private network using containers in a Ubuntu hosting machine for educational purposes.
It has an OpenWRT router connecting the hosting OS lan to its wan interface, and 2 virtual networks called lan and mgmt on additional interfaces.
Will install and initialize incus if necessary.
Will create lan and mgmt virtual networks if necessary using host 2 on each network for the router, both using /24 mask.
Will create openwrt router with incusbr0 for WAN, lan for lan, and mgmt for private management network.
Creates target containers, named using target name prefix with the container number appended.
Creates a remote admin account with sudo privilege, no passwd access, and ssh access for the user who runs this script.
Adds host names with IP addresses to /etc/hosts inside the containers and in the hosting OS.
The hosting OS will have direct access to all the virtual networks using host number 1.

Defaults
fresh:         false
prefix:        $prefix
user:          $remoteadmin
vmwarenet:     vmware dhcp assigned
lannet:        $lannetnum
mgmtnet:       $mgmtnetnum
bridgeintf:    $bridgeintf
lanintf:       $lanintf
mgmtintf:      $mgmtintf
hostnumbase:   $startinghostnum
count:         $numcontainers
nets1037:      $nets1037
verbose:       $verbose
"
            exit
            ;;
        --verbose )
            verbose=true
            ;;
        --fresh )
	    fresh="yes"
            ;;
        --prefix )
            if [ -z "$2" ]; then
                error-exit "Need a hostname prefix for the --prefix option"
 # in
            else
                prefix="$2"
                shift
            fi
            ;;
        --user )
            if [ -z "$2" ]; then
                error-exit "Need a username for the --user option"
            else
                remoteadmin="$2"
                shift
            fi
            ;;
        --lannet )
            if [ -z "$2" ]; then
                error-exit "Need a network number in the format N.N.N for the --lannet option"
            else
                lannetnum="$2"
                shift
            fi
            ;;
        --mgmtnet )
            if [ -z "$2" ]; then
                error-exit "Need a network number in the format N.N.N for the --mgmtnet option"
            else
                mgmtnetnum="$2"
                shift
            fi
            ;;
        --count )
            if [ -z "$2" ]; then
                error-exit "Need a number for the --count option"
            else
                numcontainers="$2"
                shift
            fi
            ;;
        --hostnumbase )
            if [ -z "$2" ]; then
                error-exit "Need a number for the --hostnumbase option"
            else
                startinghostnum="$2"
                shift
            fi
            ;;
        --bridgeintf )
            if [ -z "$2" ]; then
                error-exit "Need a name for the --bridgeintf option, default is $bridgeintf"
            else
                bridgeintf="$2"
                shift
            fi
            ;;
        --lanintf )
            if [ -z "$2" ]; then
                error-exit "Need a name for the --lanintf option, default is $lanintf"
            else
                lanintf="$2"
                shift
            fi
            ;;
        --mgmtinterface )
            if [ -z "$2" ]; then
                error-exit "Need a name for the --mgmtintf option, default is $mgmtintf"
            else
                mgmtintf="$2"
                shift
            fi
            ;;
        --nets1037 )
	    nets1037=true
	    ;;
    esac
    shift
done

# Start of script task execution

# install incus if needed
incus-install-check "$USER"

# need to make sure this shell has incus groups perms
if ! id -Gn|grep -q incus-admin; then

# check if user is configured for incus groups, configure if necessary
  if ! grep -q incus: /etc/group |grep -q "$(id -un)"; then
    sudo usermod -a -G incus,incus-admin "$(id -un)"
    echo "
User '$(id -un)' added to incus and incusadmin groups.
-------WARNING-------
In order to use this new permission, a new login shell is needed.
Ubuntu GUI logout doesn't logout, 'pkill systemd' or a reboot is required to actually logout.
Please reboot this vm and run this script again to finish making the containers.
---------------------
"
  fi
  exit
fi

echo "This script performs many tasks. Please be patient"
echo "To see more about what it is doing as it does it, use the --verbose option"
echo "You may ignore any messages about Open vSwitch or dpkg-preconfigure being unable to re-open stdin"
echo "DO NOT use control-Z when this script is running."

# ensure we have ssh keys
echoverbose "Setting up SSH keys for $container-mgmt"
[ -d ~/.ssh -o ! -f ~/.ssh/id_ed25519.pub ] && ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -q -N "" > /dev/null

# init incus if no incusbr0 exists yet, else get rid of old containers if fresh is requested
if ! ip a s incusbr0 >&/dev/null; then
  echoverbose "Initializing incus"
  if ! incus admin init --auto; then
    error-exit "incus init failed"
  fi
elif [ "$fresh" = "yes" ]; then
  delete-incus-containers
fi

# create lan and mgmt networks in incus
if ! ip a s $lanintf >&/dev/null; then
    incus network create $lanintf ipv4.address="$lannetnum".1/24 ipv6.address=none ipv4.dhcp=false ipv6.dhcp=false ipv4.nat=false
fi
if ! ip a s $mgmtintf >&/dev/null; then
    incus network create $mgmtintf ipv4.address="$mgmtnetnum".1/24 ipv6.address=none ipv4.dhcp=false ipv6.dhcp=false ipv4.nat=false
fi

# identify bridge interface ip address and network number
bridgeintfip=$(ip a s $bridgeintf| grep -w inet| awk '{print $2}'|sed s,/24,,)
bridgeintfnetnum=${bridgeintfip//\\.[[:digit:]]$/}
if ! valid-ip "$bridgeintfip"; then
	error-exit "Cannot find a simple single IPV4 address for $bridgeintf of hostvm in the route table. Must fix this first."
fi

# ensure hostvm has names for bridge, lan, and mgmt hostnames in hostvm's /etc/hosts
hostvmlanip="$lannetnum.1"
hostvmmgmtip="$mgmtnetnum.1"
echoverbose "Adding hostvm to /etc/hosts file if necessary"
sudo sed -i -e '/ hostvm$/d' -e '$a'"$hostvmlanip hostvm"\
            -e '/ hostvm-mgmt$/d' -e '$a'"$hostvmmgmtip hostvm-mgmt"\
            -e '/ hostvm-bridge$/d' -e '$a'"$bridgeintfip hostvm-bridge" /etc/hosts

# ensure hostvm has names for openwrt bridge, lan, and mgmt hostnames in hostvm's /etc/hosts
openwrtlanip="$lannetnum.2"
openwrtmgmtip="$mgmtnetnum.2"
echoverbose "Adding openwrt to /etc/hosts file if necessary"
sudo sed -i -e '/ openwrt$/d' -e '$a'"$openwrtlanip openwrt"\
            -e '/ openwrt-mgmt$/d' -e '$a'"$openwrtmgmtip openwrt-mgmt" /etc/hosts

# ensure hostvm has names for openwrt bridge, lan, and mgmt networks in hostvm's /etc/networks
echoverbose "Adding bridge, lan, and mgmt networks to /etc/networks"
sudo sed -i -e '/^incus-bridge /d' -e '$a'"incus-bridge $bridgeintfnetnum"\
            -e '/^lan /d' -e '$a'"lan $lannetnum"\
            -e '/^mgmt /d' -e '$a'"mgmt $mgmtnetnum" /etc/networks

##create the router container if necessary
container=openwrt
if ! incus info "$container" >&/dev/null ; then
	# launch fresh openwrt container on the bridge network
    if ! incus launch images:openwrt/23.05 "$container" -n "$bridgeintf"; then
        error-exit "Failed to create openwrt container!"
    fi
    # wait for the container to be running
    while [ "$(incus info openwrt | grep '^Status: ')" != "Status: RUNNING" ]; do sleep 2; done
    # attach lan and mgmt networks
    incus network attach $lanintf "$container" eth1
    incus network attach $mgmtintf "$container" eth2
    # update the openwrt config with config files from the repo
    filepush "$container" etc/config/dhcp ""
    filepush "$container" etc/config/network ""
    filepush "$container" etc/config/system ""
    # wait for the interfaces to configure themselves
    while ! incus list openwrt | grep -q eth2; do sleep 2; done
fi

# we want $numcontainers containers running
if [ "$nets1037" = "true" ]; then
    echo "Making NETS1037 specific containers"
    numcontainers=6
    startinghostnum=4
fi
numexisting=$(incus list -c n --format csv|grep -c "$prefix")
for (( n=0;n<numcontainers - numexisting;n++ )); do
	# override default container naming if making containers for nets1037 coourse
	if [ "$nets1037" = "true" ]; then
		case "$n" in
		    0 )
		        container=loghost
				;;
		    1 )
		        container=webhost
				;;
			2 )
		        container=nmshost
				;;
			3 )
		        container=proxyhost
				;;
			4 )
		        container=vpnhost
				;;
			5 )
				container=mailhost
				;;
		esac
	else
		# default container naming
		container="$prefix$((n+1))"
	fi
	# generate IP addresses for container
	containerbridgeintfip="$bridgeintfnetnum.$((n + startinghostnum))"
	containerlanip="$lannetnum.$((n + startinghostnum))"
	containermgmtip="$mgmtnetnum.$((n + startinghostnum))"
	# check for existing container
	if incus info "$container" >& /dev/null; then
		echoverbose "$container already exists"
		continue
	fi
	# create default container
	echoverbose "Creating $container"
	if ! incus launch images:ubuntu/"$VERSION_ID" "$container" -n $lanintf; then
		error-exit "Failed to create $container container!"
	fi

	# add container to hostvm /etc/hosts file
    echoverbose "Putting $container in /etc/hosts on hostvm"
    sudo sed -i -e "/ $container\$/d" -e "/ $container-mgmt\$/d" /etc/hosts
    sudo sed -i -e '$a'"$containerlanip $container" -e '$a'"$containermgmtip $container-mgmt" /etc/hosts

	# set up second interface and wait for container to be reachable
	echoverbose "Configuring $container networking"
	incus network attach $mgmtintf "$container" eth1
	echoverbose "Waiting for $container to complete startup"
	while [ "$(incus info "$container" | grep '^Status: ')" != "Status: RUNNING" ]; do sleep 2; done
	# set up netplan file and push it to openwrt container, then apply it
	netplanfile=$(incus exec "$container" -- grep -lR eth0 /etc/netplan)
	echoverbose "Creating netplan file $netplanfile"
	cat > $scriptdir/$container$netplanfile <<EOF
network:
    version: 2
    ethernets:
        eth0:
            addresses: [$containerlanip/24]
            routes:
              - to: default
                via: $lannetnum.2
            nameservers:
                addresses: [$lannetnum.2]
                search: [home.arpa, localdomain]
        eth1:
            addresses: [$containermgmtip/24]
EOF
	chmod 600 "$scriptdir/$container$netplanfile"
	echoverbose "Pushing $netplanfile to $container"
	incus file push "$scriptdir/$container$netplanfile" "openwrt$netplanfile"
    incus exec "$container" -- bash -c '[ -d /etc/cloud ] && echo "network: {config: disabled}" > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg'
    incus exec "$container" netplan apply
	# wait for container networking to come up
    while ! incus list "$container" | grep -q eth1; do sleep 2; done
	
    #update container /etc/hosts file
	cat > $scriptdir/$container/etc/hosts <<EOF
127.0.0.1	localhost
::1		localhost ip6-localhost ip6-loopback
ff02::1		ip6-allnodes
ff02::2		ip6-allrouters

$lannetnum.1 hostvm
$mgmtnetnum.1 hostvm-mgmt
$lannetnum.2 openwrt
$mgmtnetnum.2 openwrt-mgmt
$containerlanip $container
$containermgmtip $container-mgmt

EOF
	incus file push "$scriptdir/$container/etc/hosts" "$container/etc/hosts"
	incus file push /etc/networks "$container/etc/networks"

	# set timezone in container
    incus exec "$container" timedatectl set-timezone America/Toronto

    # set up ssh service on mgmt intf
    echoverbose "Installing openssh-server on $container-mgmt"
    incus exec "$container" -- apt-get -qq install openssh-server >/dev/null
    incus exec "$container" -- sed -i -e "s/#ListenAddress 0.0.0.0/ListenAddress $containermgmtip/" /etc/ssh/sshd_config
    incus exec "$container" -- systemctl restart ssh

	# update hostkey on hostvm for the container
    echoverbose "Removing old ssh hostkey if any for $container-mgmt"
    if [  -f ~/.ssh/known_hosts ]; then
        ssh-keygen -f ~/.ssh/known_hosts -R "$container-mgmt" >/dev/null 2>/dev/null
    fi
    echoverbose "Retrieving hostkey for $container"
    ssh-keyscan -H "$container"-mgmt >>~/.ssh/known_hosts 2>/dev/null >/dev/null

    # create remoteadmin user in container and add our pubkey to authorized_keys
	echoverbose "Adding remote admin user '$remoteadmin' to $container"
    incus exec "$container" -- useradd -m -c "SSH remote admin access account" -s /bin/bash -o -k UID_MIN=0 -u 0 "$remoteadmin"
    incus exec "$container" mkdir "/home/$remoteadmin/.ssh"
    incus exec "$container" chmod 700 "/home/$remoteadmin/.ssh"
    incus exec "$container" cp "/home/$remoteadmin/.ssh/id_ed25519.pub" "/home/$remoteadmin/.ssh/authorized_keys"
    incus exec "$container" chmod 600 "/home/$remoteadmin/.ssh/authorized_keys"
    incus exec "$container" -- chown -R "$remoteadmin" "/home/$remoteadmin"

	# create account for current user in container with our current keys and add our pubkey to authorized_keys
    username="$(id -un)"
    userdescrip="$(grep ^$username: /etc/passwd|cut -d: -f5)"
    shadowentry="$(sudo grep ^$username: /etc/shadow| cut -d: -f 2)"
    echoverbose "Adding remote user '$(id -un)' to $container"
    incus exec "$container" -- useradd -m -c "$userdescrip" -s /bin/bash "$username"
    incus exec "$container" -- adduser "$username" sudo
    incus exec "$container" -- sed -i -e "/^$username:/s,!,$shadowentry," /etc/shadow
    incus exec "$container" mkdir "/home/$username/.ssh"
    incus exec "$container" chmod 700 "/home/$username/.ssh"
    incus file push ~/.ssh/id_ed25519 "$container/home/$username/.ssh/"
    incus file push ~/.ssh/id_ed25519.pub "$container/home/$username/.ssh/"
    incus exec "$container" cp "/home/$username/.ssh/id_ed25519.pub" "/home/$username/.ssh/authorized_keys"
    incus exec "$container" chmod 600 "/home/$username/.ssh/authorized_keys"
    incus exec "$container" -- chown -R "$username" "/home/$username"

	# set hostname in the container
    echoverbose "Setting $container hostname"
    incus exec "$container" hostnamectl set-hostname "$container"

	# restart container to ensure everything is clean
    echoverbose "Restarting $container"
    incus restart "$container"
    echo "Waiting for $container restart"
    while [ "$(incus info "$container" | grep '^Status: ')" != "Status: RUNNING" ]; do sleep 2; done
    while ! incus list "$container" | grep -q eth1; do sleep 2; done
done

# setup for NETS1037 course containers
if [ "$nets1037" = "true" ]; then
    echoverbose "Doing setup for NETS1037 course containers"
	echoverbose "Install certs as needed"
    build-and-push-certs
    for container in loghost mailhost webhost proxyhost vpnhost nmshost; do
		# override defaultcontainer hosts file with course-specific hosts file
		echoverbose "Setting up /etc/hosts files on $container"
		filepush "$container" etc/hosts ""

  		# do per-host setups
		case "$container" in
			loghost )
				echoverbose "Doing $container specific setup"
				# software installs first
   				if ! packageinstalls "$container" mysql-server rsyslog-mysql rsyslog-relp; then
	  				echoverbose "Package installs failed, leaving $container unconfigured"
	  				continue
	  			fi
				# install config files from github repo
				filepush "$container" etc/rsyslog.conf rsyslog 
				;;
		mailhost )
			echoverbose "Doing $container specific setup"
			# software installs first
   			if ! packageinstalls "$container" postfix dovecot-imapd mailutils apache2 roundcube; then
	  			echoverbose "Package installs failed, leaving $container unconfigured"
	  			continue
	  		fi
			# install config files from github repo
			filepush "$container" etc/rsyslog.d/loghost.conf rsyslog
   			;;
		webhost )
			echoverbose "Doing $container specific setup"
			# software installs first
   			if ! packageinstalls "$container" postfix dovecot-imapd mailutils apache2 roundcube; then
	  			echoverbose "Package installs failed, leaving $container unconfigured"
	  			continue
	  		fi
			# install config files from github repo
			filepush "$container" etc/rsyslog.d/loghost.conf rsyslog
			;;
		nmshost )
			echoverbose "Doing $container specific setup"
			# software installs first
   			if ! packageinstalls "$container" apache2; then
	  			echoverbose "Package installs failed, leaving $container unconfigured"
	  			continue
	  		fi
			# install config files from github repo
			filepush "$container" etc/rsyslog.d/loghost.conf rsyslog
			;;
		proxyhost )
			echoverbose "Doing $container specific setup"
			# software installs first
   			if ! packageinstalls "$container" squid; then
	  			echoverbose "Package installs failed, leaving $container unconfigured"
	  			continue
	  		fi
			# install config files from github repo
			filepush "$container" etc/rsyslog.d/loghost.conf rsyslog
			;;
		vpnhost )
			echoverbose "Doing $container specific setup"
			# software installs first
   			if ! packageinstalls "$container" apache2; then
	  			echoverbose "Package installs failed, leaving $container unconfigured"
	  			continue
	  		fi
			# install config files from github repo
			filepush "$container" etc/rsyslog.d/loghost.conf rsyslog
            (cd ansible-files; ansible-playbook -i inventory.ini vpnsetup-playbook.yaml)
			;;
	esac
 done
fi
