#!/bin/bash

TODAY=`date +%Y%m%d`

for LOGFILE in `find -P /var/www/ -iname "*.log" -print | grep "shared/log"`
do
  `cat $LOGFILE >> $LOGFILE.${TODAY}; echo "" > $LOGFILE; gzip -f $LOGFILE.${TODAY}`
done

