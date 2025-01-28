# NETS1037-03 - Log Analysis

## Overview
This lesson introduces some tools and techniques for summarizing and analyzing log messages in the context of security event recognition. It is expected to be completed in week 4 of the course, with the quiz due before the start of the following class. 

## Learning Objectives
At the end of this lesson, students will be able to:
  * demonstrate tools for regular reporting of events found in logs
  * use software tools to analyze and refine logs
  * create a webapp server and integrate it into the lab network, to provide graphical log analyis tools

These objectives are in support of Learning Outcomes 3 and 4 in the Course Outline.

## To do List
   * Read through the [presentation slides](Presentations/NETS1037-03-LogAnalysis.pdf)
   * Watch the recorded video of the presentation found in the general chat of the Microsoft Team for this course if you did not attend the class when it was presented
   * Review the lesson materials linked below
   * Perform the learning activities as described below
   * Do the quiz found under Tests on [Blackboard](https://gc.blackboard.com) for this topic

## Lesson Material
  * [Presentation slides in PDF format](Presentations/NETS1037-03-LogAnalysis.pdf)
  * Recorded video of the presentation found in the general chat of the Microsoft Team for this course

## Learning Activity
In this lab assignment, you will be creating a virtual machine for a Linux-based web application server, suitable for use in the rest of the assignments in this course. Follow the instructions in the [Lab 3 - Log Analysis](Labs/Lab03-LogAnalysis.html).

## Online Resources - documentation and examples for software used in this lab
* [logwatch project on sourceforge - latest version source](https://sourceforge.net/projects/logwatch/)
* [logwatch overview on ArchWiki](https://wiki.archlinux.org/title/Logwatch)
* [fwlogwatch project page at inside-security.de](http://fwlogwatch.inside-security.de/)
* [analog CE](https://www.c-amie.co.uk/software/analog/)
* [fwanalog man page at ubuntu.com](http://manpages.ubuntu.com/manpages/focal/man1/fwanalog.1.html)
* [Apache HTTP server project](https://httpd.apache.org/)
* [MySQL site at Oracle](https://www.mysql.com/)
* [MariaDB workalike for MySQL](https://mariadb.org/)
* [Loganalyzer software download](http://download.adiscon.com/loganalyzer/loganalyzer-4.1.12.tar.gz)
* [webhost loganalyzer installation web page](http://webhost.home.arpa/loganalyzer/install.php)
* [loganalyzer installed and running on webhost](http://webhost.home.arpa/loganalyzer)

## Graded Activity
When you are done this lab, you can check the rubric for this assignment on [Blackboard](https://gc.blackboard.com) to ensure you have completed everything that is marked and then submit the results of running the [webhost check script](Labs/Lab03-webhost-checks.sh) on your loghost, as text. The lab instructions have a detailed section describing what to submit to Blackboard for this assignment.

## Quiz

The quiz is found on Blackboard under Assignments and Tests.

## Test

There is no separate test for this topic. The quiz will count for your testing mark in this topic.

## Summary
In this module, you have been introduced to software used to analyze, summarize, and report on log messages.
You should now be able to:
  * implement daily reporting on your logs
  * use web applications to search for and delve into detailed log data
  * created and correctly configured a web server to provide log analysis applications, as well as automated log reporting for any server that has logs

Completing the quiz will provide you with a measure of your knowledge in these areas. For the next class you should have your private virtual network ready, as well as your log server and Windows desktop client.
