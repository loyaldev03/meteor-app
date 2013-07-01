#!/bin/bash

DATE=`date +"%Y-%m-%d_%H-%M-%S"`
MASTER_MYSQL_IP=db1.stoneacrehq.com
SLAVE_MYSQL_IP=reporting1.stoneacrehq.com
MYSQL_USER=root
MYSQL_PASSWORD=pH03n[xk1{{s
SOURCE_DATABASE=sac_production
DESTINATION_DATABASE=sac_production_reporting
BACKUP_FILE_RAW=/tmp/backup_replication
SHOW_MASTER_STATUS_LOG=/tmp/show_master_status_log
MASTER_BACKUP_SQL=master-backup.sql

################## Stop replication ##################################################
# stop slave and do backup
echo `date` "Stopping slave"
mysqladmin stop-slave -u $MYSQL_USER -p$MYSQL_PASSWORD -hSLAVE_MYSQL_IP
################## Start mysql master replication ##################################################
echo `date` "Starting master replication"
mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -h$MASTER_MYSQL_IP < $MASTER_BACKUP_SQL > $SHOW_MASTER_STATUS_LOG
MASTER_LOG_FILE=`grep 'mysql-bin' salida.txt | awk '{ print $1 }'`
MASTER_LOG_POS=`grep 'mysql-bin' salida.txt | awk '{ print $2 }'`
################## Start mysql slave loading ##################################################
# load backup into new database
echo `date` "Loading slave backup"
mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -h$SLAVE_MYSQL_IP $DESTINATION_DATABASE < $BACKUP_FILE_RAW
echo `date` "Changing master"
mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -h$SLAVE_MYSQL_IP < _EOF_
CHANGE MASTER TO MASTER_HOST='$MASTER_MYSQL_IP', MASTER_USER='slave_sac', MASTER_PASSWORD='GEJ4wu7eves5uh', MASTER_LOG_FILE='$MASTER_LOG_FILE', MASTER_LOG_POS=$MASTER_LOG_POS;
_EOF_
echo `date` "Start slave"
mysqladmin start-slave -u $MYSQL_USER -p$MYSQL_PASSWORD -hSLAVE_MYSQL_IP
echo `date` "Remove backup file"
# remove backup
rm $BACKUP_FILE_RAW



