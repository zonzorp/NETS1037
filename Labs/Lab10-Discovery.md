# Network Discovery
In this lab, we will be using network discovery tools. You may install these tools on nmshost, a Windows machine attached to the lab network private LAN, or a Mac attached to the lab network private LAN for this lab.

## Install nmap if necessary
Install the nmap command line tool, as well as a GUI for it. You may use any nmap GUI tool you like. zenmap is popular and may be obtained from the [nmap.org website](https://nmap.org). If the computer you will be using for this lab already has nmap, you do not need to reinstall it. 

## Obtain the nmap reference ebook
You can read about half of the nmap ebook on the [nmap.org website](https://nmap.org). It will provide you with a reference for the tools and examples of using it for network discovery. The full book is available for purchase, but we do not need the full book for our lab.

## NMAP
We are going to review the various techniques for doing network discovery using nmap. nmap can be used to go much deeper into specific hosts and services than we do in this lab. Our primary purpose is to determine what is on our network. Our test machine is connected to multiple networks, and it is important to not do any intrusive scanning of networks which do not belong to us. So be very careful with what scans you run against which networks.
1. Scan your directly connected network as an ordinary user (NOT root). Then try the same scan using sudo. On a Ubuntu or similar machine, this is easily done from the command line. If you are using nmshost for this lab, use your host machine's LAN address instead of `hostname -i`.
```bash
nmap -sn `hostname -i`/24
sudo nmap -sn `hostname -i`/24
```
Did you get a different result from scanning with sudo?
1. Carefully scan your ISP's network which you are directly connected to. You can get your external IP address using `curl icanhazip.com`. Since we do not necessarily know what subnet mask our ISP is using, you can try it with a 24 bit mask to see how it works.
```bash
nmap -sn `curl icanhazip.com`/24
sudo nmap -sn `curl icanhazip.com`/24
```
Did you get a different result from scanning with sudo? From the two different networks scanned, do you notice anything about the extra hosts that likely showed up when using sudo that might give you hints about why you needed sudo to discover them? If not, review the section in the nmap ebook regarding [host discovery controls](https://nmap.org/book/host-discovery-controls.html).
1. Carefully scan the network that zonzorp.net is attached to. DO NOT USE sudo or a root account, as we do not own this entire network.
```bash
nmap -sn zonzorp.net/23
```
From the result of the scan, what can you say about the network that zonzorp.net is attached to?

## Wireshark
We can do some simple discovery on our network using wireshark/tshark. You can use either tool, as you choose.
1. Run a network capture on your LAN, using any packet capture tool you wish. Do not filter the capture in order to get as wide a variety of traffic as possible.
1. While the capture runs, generate some traffic so the capture has some content.
   1. check your email
   1. access blackboard and georgiancollege.ca websites
   1. go to youtube and start playing at least one youtube video for at least 10 seconds
   1. do an image search on google.com, then open a few of the images it finds
1. End the network capture, and use the saved capture file for your wireshark/tshark reporting.
1. Use wireshark or tshark to generate the IP endpoints report, the tcp endpoints report, and the udp endpoints report.

Screenshot the reports from wireshark/tshark, and add your own comments to describe the results. Did you see any unexpected hosts, protocols, or connections?

## Automated Discovery with PRTG
Paessler offers commercial monitoring services and software. Their PRTG product can be run in trial mode and has a free use license for small networks. As part of the installation, it can do network discovery by running probes and various agent programs.

## PRTG
To see what automated discovery can look like, we will install PRTG and allow it to run a discovery on our network.
1. [Download the PRTG software with a trial license](https://www.paessler.com/download/prtg-download?download=1)
1. Install it on a Windows VM, a Windows computer, or run it using [mono](https://www.mono-project.com/) under Linux
1. Start PRTG and click the appropriate buttons to allow it to run an automated discovery on your network; the results will be more interesting if you allow it to run directly on your actual LAN

There is nothing to submit for PRTG, it is simply to experience the difference using commercially-funded software can make in the user-friendliness of these kinds of tools.

## Grading
This lab is graded and counts towards your semester mark. Submit the questions found above with your answers as a PDF. DO NOT submit a Word document. Only PDFs will be accpeted.
