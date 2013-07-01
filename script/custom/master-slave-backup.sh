#!/bin/bash

MASTER_MYSQL_IP=db1.stoneacrehq.com
MYSQL_USER=root
MYSQL_PASSWORD=pH03n[xk1{{s
SOURCE_DATABASE=sac_production
BACKUP_FILE_RAW=/tmp/backup_replication

################## Database dump ##################################################
echo `date` "Doing backup"
mysqldump -u $MYSQL_USER -p$MYSQL_PASSWORD -h$MASTER_MYSQL_IP $SOURCE_DATABASE > $BACKUP_FILE_RAW
################## End Database dump ###############################################

