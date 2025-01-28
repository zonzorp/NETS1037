# Lab LAN creation

This lab uses VMWare Fusion for Mac, or VMWare Workstation for Windows.
VMWare Player will not suffice.
You can use VirtualBox, but there is a different setup for the virtual network, and detailed instructions are not provided for VirtualBox.
This lab assumes you have learned to setup similar machines in the previous semester's NETS1028 course.
For the router, use pfsense which you can download from [pfsense.org](https://pfsense.org) or import a prebuilt VM using the intructions below.

## Set up private network in vmware
### In VMWare properties, add a private network which
 * is not able to connect to the outside world through the host OS using NAT (host-only network)
 * is connected to the host OS so that your host machine can talk to both sides of your router
 * does not provide addresses to the private network via dhcp
 * uses 192.168.16.0/24 for the network addresses
 * screenshot the private network properties - **This is one of the screenshots you need to submit for this lab.**

Take note of this network address block, your host will appear as host 1 on that network. All your VMs for this course will be going on this network and have static addresses. We will refer to this network as our lab LAN.

##Import the prebuilt router vm
  * Download the [exported VM](https://zonzorp.net/gc/NETS1037-pfsense-starting-vm.ova).
  * Check that VMWare has attached the right networks to your imported VM:
    * first network interface on NAT, which is our router's WAN
    * second interface on the private network you created before importing the VM, which is our router's LAN
  * Open the administration web app (http://your-router-ip/) on the router VM to ensure you can log in to it properly, and screenshot the console display after login on the web app. **This is one of the screenshots you need to submit for this lab.**

If you prefer to build a router VM from scratch, detailed instructions are further down this web page, after the Grading section.

## Create a snapshot
Shutdown the VM by choosing the Halt option on the console, or using the Diagnostics->Halt System option in the web interface.

When the VM has finished shutting down, use your file manager to find the files for your VM, which typically will be in a directory called `Virtual Machines` in your home directory. Open the file for your vm called VMNAME.vmx and add the following line to the end of the file.
```bash
disk.EnableUUID = "TRUE"
```

Now use the VM or Virtual Machine menu in VMWare to create a snapshot. You should create a snapshot after every lab is completed, so that if you mess something up, the worst impact is that you will have to go back to your snapshot and redo the current lab. If you don't have the snapshots, you will have to start back at lab 0 if you mess up your VM during the semester. Once you have made the snapshot, you can run the VM again in VMWare so that it is ready for use in the next lab.

## Grading
This lab is marked. To submit this assignment on Blackboard, include the 2 screenshots described above. Submit the image files only. DO NOT SUBMIT MICROSOFT OFFICE FILES SUCH AS WORD OR POWERPOINT OR EXCEL FILES.


## OPTIONAL - ONLY DO THIS IF YOU DON'T WANT TO IMPORT THE PREBUILT VM:
### Create a VM for a router with two ethernets
 1. Connect the first interface to the VMWare NAT network (automatic setting can be used) - this will be used as the wan interface
 1. Connect the second one to the private network you created to be used as the lan interface

### Install pfsense
 1. Start your VM in the VMWare virtual machine library window
 1. Select to install using the pfsense ISO downloaded from pfsense.org
 1. Configure the router wan connection as a dhcp client
 1. On the console after boot, configure the router lan to have a static IP using host number 2 on whatever network ip address block VMWare assigned to your private LAN and have the router provide dhcp service to the lan

### Configure the pfsense router to allow private address blocks on the WAN interface
  1. Connect to your pfsense router's lan ip using a web browser on your host laptop
  1. Login as admin with password pfsense
  1. Click through the initial setup wizard, setting the timezone
  1. Scroll to the bottom of the WAN interface configuration page and uncheck the box that disallows using private netblocks on the WAN
  1. Run the updates when offered, and let it reboot
  1. Your pfsense router should now be able to talk to the internet
  1. You can customize the dashboard if you want
  
### Configure the router to have names in the DNS resolver so you can use them on your private LAN
  1. In the pfsense web interface, click on **Services->DNS Resolver**
  1. Scroll to the bottom of the page, and look for the section called **Host Overrides**
  1. Click on the **+ Add** button
  1. Fill in a name for your host computer (e.g. **laptop**)
  1. Fill in **home.arpa** as the domain name, since we will not be using a real domain name
  1. Fill in the host's LAN IP for the private network (i.e. host 1 on the network block VMWare assigned to your new private LAN)
  1. Click on **Save**
  1. Scroll down to the **Host Overrides** again
  1. Using the **+ Add** button again, this time add a name for your router (like **pfsense**)in domain **home.arpa**, with host number 2 on the private LAN and **Save** that
  1. Click **Apply** to apply the new names to your DNS resolver's configuration
  1. Click on **Diagnostics->Ping** and put your router's name in as the target, then start the ping test to verify the hostname works


