# Set up Radius AAA authentication for SSH using FreeRadius
We will be using loghost as a RADIUS service host and implementing use of that service for testuser to login using ssh on loghost. So you will need to be on loghost to do the activities for this lab. webhost and nmshost do not need to be running for this lab.

## Install the RADIUS daemon
1. Install freeradius on your loghost
```bash
ssh loghost
sudo apt update
sudo apt install freeradius
```

1. Use netstat to verify that your radius server is listening on the default ports for connections
```bash
sudo netstat -tulpn
```

## Configure logging and identify the RADIUS secret
Freeradius configuration files are kept under `/etc/freeradius`.
1. Modify your `radiusd.conf` to log auth messages to syslog by changing `no` to `yes` on the `auth =` line.
1. Find the default RADIUS secret for the localhost client in the `clients.conf` file.
```bash
sudo sed -i --follow-symlinks -e 's/auth = no/auth = yes/' /etc/freeradius/3.0/radiusd.conf
sudo grep '^       secret = ' /etc/freeradius/3.0/clients.conf
```

## Add a test user to the RADIUS user database and verify it looks up correctly and logs correctly
1. Create a test user for authentication by adding a line to the start of the users file and restart your radiusd
```bash
grep -q testuser /etc/freeradius/3.0/users || sudo sed -i --follow-symlinks '1i#User for lab 8\ntestuser Cleartext-Password := "radiuspassword"\n' /etc/freeradius/3.0/users
sudo systemctl enable freeradius
sudo systemctl restart freeradius
```

1. Use `radtest` to verify you can get a successful authentication of your test user, and also do one with an incorrect password
```bash
radtest testuser radiuspassword localhost 1 testing123
radtest testuser badpass localhost 1 testing123
```

1. Check your `/var/log/freeradius/radius.log` to see what got recorded
```bash
tail /var/log/freeradius/radius.log
```

1. Try using `radtest` for your test user with an incorrect secret
```bash
radtest testuser password localhost 1 badsecret
tail /var/log/freeradius/radius.log
```

1. Try to connect to loghost as user testuser
   * Did it work?
   * What was logged to the `/var/log/freeradius/radius.log` and `/var/log/auth.log` files?


## Create a login account for the name testuser in Linux and configure sshd to include RADIUS for authentication checks
1. Add the testuser account to your loghost as a local user with the adduser command and give that account sudo privileges
   * Set the password to be something different from what you used for the freeradius user definition
```bash
sudo adduser testuser
sudo adduser testuser sudo
```

1. Configure pam_radius_auth with the correct secret for localhost to access RADIUS
1. Configure sshd to include RADIUS as an authentication source via PAM
```bash
sudo apt install libpam-radius-auth
sudo sed -i --follow-symlinks '/127.0.0.1/s/secret/testing123/' /etc/pam_radius_auth.conf
sudo sed -i --follow-symlinks '1i# Adding radius auth for lab 8\nauth sufficient pam_radius_auth.so\n' /etc/pam.d/sshd
```

1. Use ssh to connect to loghost as user testuser
   * Try the password in radius (*radiuspassword*)
   * Try the linux password (*whatever you made it*)
   * Try an invalid password
1. Which password(s) is/are accepted?
1. What was logged to the `/var/log/freeradius/radius.log` and `/var/log/auth.log` files?

## Effect of using RADIUS with SSH on other methods of login
1. Login on the console of loghost as user testuser
   * Try the password in radius (*radiuspassword*)
   * Try the linux password (*whatever you made it*)
   * Try an invalid password
1. Which password(s) was/were accepted?
1. What was logged to the `/var/log/freeradius/radius.log` and `/var/log/auth.log` files?

## Restricting SSHD to only RADIUS authentication
1. Disable standard UNIX authentication for sshd
```bash
sudo sed -i --follow-symlinks 's/^@include common-auth/#@include common-auth/' /etc/pam.d/sshd
```

1. Use ssh to connect to loghost as user testuser
   * Try the password in radius (*radiuspassword*)
   * Try the linux password (*whatever you made it*)
   * Try an invalid password
1. Which password(s) was/were accepted?
1. What was logged to the `/var/log/freeradius/radius.log` and `/var/log/auth.log` files?

## Grading
Screenshot the following commands and their output run on loghost:
```bash
radtest testuser radiuspassword localhost 1 testing123
radtest testuser badpass localhost 1 testing123
radtest testuser password localhost 1 badsecret
ssh testuser@loghost
tail -n 20 /var/log/freeradius/radius.log /var/log/auth.log
```
Submit your screenshots on blackboard.

