#!/bin/bash

DATE=`date +"%Y-%m-%d_%H-%M-%S"`
MASTER_MYSQL_IP=db1.stoneacrehq.com
SLAVE_MYSQL_IP=127.0.0.1
MYSQL_USER=root
MYSQL_PASSWORD=pH03n[xk1{{s
DESTINATION_DATABASE=sac_production
BACKUP_FILE_RAW=/tmp/backup_replication
SHOW_MASTER_STATUS_LOG=/tmp/show_master_status_log
MASTER_SLAVE_BACKUP_SCRIPT=`pwd`/master-slave-backup.sh
REPLICATION_USER=slave_sac
REPLICATION_PASSWORD=GEJ4wu7eves5uh

################## Stop replication ##################################################
# stop slave and do backup
echo `date` "Stopping slave"
mysqladmin stop-slave -u $MYSQL_USER -p$MYSQL_PASSWORD -h$SLAVE_MYSQL_IP
################## Start mysql master replication ##################################################
echo `date` "Starting master replication"
mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -h$MASTER_MYSQL_IP -e"use $DESTINATION_DATABASE; FLUSH TABLES WITH READ LOCK; SHOW MASTER STATUS; SYSTEM $MASTER_SLAVE_BACKUP_SCRIPT; UNLOCK TABLES;" > $SHOW_MASTER_STATUS_LOG
MASTER_LOG_FILE=`grep 'mysql-bin' $SHOW_MASTER_STATUS_LOG | awk '{ print $1 }'`
MASTER_LOG_POS=`grep 'mysql-bin' $SHOW_MASTER_STATUS_LOG | awk '{ print $2 }'`
echo $MASTER_LOG_FILE
echo $MASTER_LOG_POS
################## Start mysql slave loading ##################################################
# load backup into new database
echo `date` "Loading slave backup"
mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -h$SLAVE_MYSQL_IP $DESTINATION_DATABASE < $BACKUP_FILE_RAW
echo `date` "Changing master"
mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -h$SLAVE_MYSQL_IP -e"CHANGE MASTER TO MASTER_HOST='$MASTER_MYSQL_IP', MASTER_USER='$REPLICATION_USER', MASTER_PASSWORD='$REPLICATION_PASSWORD', MASTER_LOG_FILE='$MASTER_LOG_FILE', MASTER_LOG_POS=$MASTER_LOG_POS;"
echo `date` "Start slave"
mysqladmin start-slave -u $MYSQL_USER -p$MYSQL_PASSWORD -h$SLAVE_MYSQL_IP
echo `date` "Remove backup file"
# remove backup
rm $BACKUP_FILE_RAW
