#!/bin/bash
#use GREP to extract the host using CUT from log entries containing CONNECT
cat /usr/local/squid/var/logs/access.log.0 | grep CONNECT | cut -d “/” -f 2 | cut -d ” ” -f 4 > squid_ssl.log

#sort the file and report the unique entries, storing the output in a temp file
sort squid_ssl.log > squid_ssl2.log
uniq -c squid_ssl2.log | sort -r > squid_ssl.log

#use GREP to extract the host using CUT from log entries containing HTTP
cat /usr/local/squid/var/logs/access.log.0 | grep http | cut -d “/” -f 4 > squid_http.log

#sort the file and report the unique entries, storing the output in a temp file
sort squid_http.log > squid_http2.log
uniq -c squid_http2.log | sort -r > squid_http.log

#merge the two temp files together in a descending order
sort -r squid_http.log squid_ssl.log > squid_compiled.log

#insert pretty headers
echo “———————————————” > squid-final.log
echo “Most heavily visited sites” >> squid-final.log
echo “———————————————” >> squid-final.log

#use head to show only the sites with highest hit count
head squid_compiled.log >> squid-final.log

#do the whole process for cache HITS
cat /usr/local/squid/var/logs/access.log.0 | grep http | grep HIT | cut -d “/” -f 4 > squid_hits.log
sort squid_hits.log > squid_hits2.log
uniq -c squid_hits2.log | sort -r > squid_hits.log

echo “———————————————” >> squid-final.log
echo “Sites with highest cache hit count” >> squid-final.log
echo “———————————————” >> squid-final.log

head squid_hits.log >> squid-final.log

#cleanup – comment this out for debugging
rm squid_*



#### Ausgabe ###
#———————————————
#Most heavily visited sites
#———————————————
#13765 192.168.254.1
#5734 img100.xvideos.com
#4661 stork48.dropbox.com
#4378 m.google.com:443
#2484 profile.ak.fbcdn.net
#1778 http://www.facebook.com
#1716 http://www.google.co.uk
#1318 0.59.channel.facebook.com
#1297 http://www.google-analytics.com
#1249 http://www.google.com
#———————————————
#Sites with highest cache hit count
#———————————————
#335 img100.xvideos.com
#192 s7.addthis.com
#125 http://www.cisco.com
#125 static.ak.fbcdn.net
#109 r.mzstatic.com
#109 mmv.admob.com
#97 ebooks-it.org
#92 profile.ak.fbcdn.net
#84 pagead2.googlesyndication.com
#80 cachend.fling.com
#
#I don’t expect this to be placed in anyone’s production environment,  but if you’re considering it, be aware that it’s probably better to integrate the #script with a MySQL database if there is significant traffic. It will make it much more robust, archivable and reportable. If you go down this path, #research the following for a start:
# mysql -u[user] -p[pass] -e "[mysql commands]


#“head squid_compiled.log”
#to:
#“head -n 20 squid_compiled.log”
#to display 20 lines





#Hello to every one use this script for Cache Hits only and put in crontab to generate auto report
#this script will show you always current or last reports to not mix-up with old reports I deleted the file in the start thanks. have a fun. and appreciate to owner of script 0 0 * * * /usr/local/squid/bin/squid -k rotate
#put in the crontab file to not squid log become heavy

#!/bin/bash
#rm /var/log/squid/squid-final.log
#cat /var/log/squid/access.log | grep HIT | cut -d, -f 4 > squid_hits.log
#sort squid_hits.log > squid_hits2.log
#uniq -c squid_hits2.log | sort -r > squid_hits.log

#echo ——————————————————————————->> squid-final.log
#echo Sites with highest cache hit count >> squid-final.log
#echo TCP_HIT/200 means restored content from cache 100% >> squid-final.log
#echo ——————————————————————————->> squid-final.log
#head squid_hits.log >> squid-final.log
#cleanup – comment this out for debugging
#rm squid_*



