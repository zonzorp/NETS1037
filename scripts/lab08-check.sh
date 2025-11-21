#!/bin/bash
# marking script for UTM lab

score=0
# retrieve the 3 web resources without using the UTM
unset http_proxy
if ! wget -q -O /tmp/UTMlab$$.index.txt https://zonzorp.net ; then
	echo "Failed to retrieve https://zonzorp.net without using a proxy
	echo You must fix this before your lab can be marked
	rm /tmp/UTMlab$$.index.txt 2>/dev/null
	exit 1
else
	wget -q -O /tmp/UTMlab$$.eicar.com.txt https://zonzorp.net/gc/eicar.com.txt
	wget -q -O /tmp/UTMlab$$.eicar.com.zip https://zonzorp.net/gc/eicar.com.zip
fi

# set the proxy to use the UTM and retrieve the resources again for comparison
export http_proxy=http://proxyhost.home.arpa:8080

if ! wget -O /tmp/UTMlab$$.zindex.txt http://zonzorp.net 2>zindex.log ; then
	echo "Failed to retrieve http://zonzorp.net using proxyhost:8080
	echo You must fix this before your lab can be marked
	rm /tmp/UTMlab$$.* 2>/dev/null
	exit 1
else
	wget -O /tmp/UTMlab$$.zeicar.txt http://zonzorp.net/gc/eicar.com.txt 2>zeicartxt.log
﻿	wget -O /tmp/UTMlab$$.zeicar.zip http://zonzorp.net/gc/eicar.com.zip 2>zeicarzip.log
fi

if ! cmp /tmp/UTMlab$$.index.txt /tmp/UTMlab$$.zindex.txt 2>/dev/null; then
	echo Unable to properly retrieve a valid web resource using the UTM
	echo Ensure your proxy is responding
	echo Hint: try using wget on the command line to ensure it is working properly before re-running this check script
	echo Your current mark is $score, fix the problem and re-run this script to get a better score
	rm /tmp/UTMlab$$.* 2>/dev/null
	exit
else
	score+=20
	echo 20 marks awarded for UTM-proxied valid resource retrieval
fi

if ! grep -aqi "eicar" /tmp/UTMlab$$.zeicar.txt 2>/dev/null; then
	echo Unable to properly block a detected virus using the UTM
	echo Ensure your UTM is properly scanning content with clamav
	echo Hint: try using wget http://zonzorp.net/gc/eicar.com.txt on the command line to ensure it is working properly before re-running this check script
	echo Your current mark is $score, fix the problem and re-run this script to get a better score
	rm /tmp/UTMlab$$.* 2>/dev/null
	exit
else
	score+=40
	echo 40 marks awarded for UTM-proxied banned content blocking
fi

if ! grep -aqi "Banned File Extension" /tmp/UTMlab$$.zeicar.zip 2>/dev/null; then
	echo Unable to properly block a banned filetype using the UTM
	echo Ensure your UTM is blocking banned filetypes
	echo Hint: try using wget on the command line to ensure it is working properly before re-running this check script
	echo Your current mark is $score, fix the problem and re-run this script to get a better score
	rm /tmp/UTMlab$$.* 2>/dev/null
	exit
else
	score+=40
	echo 40 marks awarded for UTM-proxied banned filetype blocking
fi

Your lab score is $score.

