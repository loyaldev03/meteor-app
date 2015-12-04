#!/bin/bash

TODAY=`date +%Y%m%d`

# Empty logs related to jenkins proyects.
for LOGFILE in `find -P /var/lib/jenkins/workspace/ -iname "*.log" -print`
do
 `truncate -s 0 $LOGFILE`
done

for LOGFILE in `find -P /var/www/ -iname "*.log" -print | grep "shared/log"`
do
  `cat $LOGFILE >> $LOGFILE.${TODAY}; echo "" > $LOGFILE; gzip -f $LOGFILE.${TODAY}`
done

for LOGFILE in `find -P /opt/nginx/logs/ -iname "*.log" -print`
do
  mv $LOGFILE $LOGFILE.${TODAY}
  kill -USR1 `cat /opt/nginx/logs/nginx.pid`
  gzip -f $LOGFILE.${TODAY}
done
