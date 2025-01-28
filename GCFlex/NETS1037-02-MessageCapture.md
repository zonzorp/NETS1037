# NETS1037-02 - Log Message Capture

## Overview
This lesson covers the common methods by which log messages are generated, transmitted, and stored. It is expected to be completed in weeks 2 and 3 of the course, with the quiz due before the start of the 4th class. 

## Learning Objectives
At the end of this lesson, students will be able to:
  * integrate multiple storage mechanisms for log messages
  * implement multiple protocols for log message transmission
  * create a log server and centralize logging for MacOS, Windows, Linux, and network devices

These objectives are in support of Learning Outcomes 2, 3, and 4 in the Course Outline.

## To do List
   * Read through the [presentation slides](Presentations/NETS1037-02-MessageCapture.pdf)
   * Watch the recorded video of the presentation found in the general chat of the Microsoft Team for this course if you did not attend the class when it was presented
   * Review the lesson materials linked below
   * Perform the learning activities as described below
   * Do the quiz found under Tests on [Blackboard](https://gc.blackboard.com) for this topic

## Lesson Material
  * [Presentation Slides in PDF format](Presentations/NETS1037-02-MessageCapture.pdf)
  * Recorded video of the presentation found in the general chat of the Microsoft Team for this course
  * [Instructions for centralizating Windows eventlogs in a Windows-only environment](https://www.loggly.com/ultimate-guide/centralizing-windows-logs/)

## Learning Activity
In this lab assignment, you will be creating virtual machines for a Linux-based log server and a desktop Windows client, suitable for use in the rest of the assignments in this course. Follow the instructions in the [Lab 2](Labs/Lab02-loghost.html).

## Graded Activity
When this lab is done, a part of the marks for this lab will be for the correct creation of this virtual network with router as described in the previous lab. The rest of the marks will be for the correct setup of centralized logging from pfsense, Windows, and loghost to both the file store and database on loghost, as described in the instructions for this lab. When you are done this lab, you can check the rubric for this assignment on [Blackboard](https://gc.blackboard.com) to ensure you have completed everything that is marked and then submit the results of running the [loghost check script](Labs/Lab02-loghost-checks.sh) on your loghost, as text. The lab instructions describe doing this graded activity.

## Quiz
There is a quiz for this topic, found on [Blackboard](https://gc.blackboard.com) under Tests.

## Test
There is no separate test for this topic. The quiz will count for your testing mark in this topic.

## Summary
In this module, you have been introduced to protocols and software to generate, transmit, and store log messages in multiple operating systems.
You should now have:
  * integrated multiple storage mechanisms for log messages
  * implemented multiple protocols for log message transmission
  * created and correctly configured a log server to provide centralize logging suitable for MacOS, Windows, Linux, and network devices

Completing the quiz will provide you with a measure of your knowledge in these areas. For the next class you should have your private virtual network ready, as well as your log server and Windows desktop client.
