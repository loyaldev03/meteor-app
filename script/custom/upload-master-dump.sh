#!/bin/bash

BACKUP_FILE_RAW=/app/tmp/db_dump/phoenix-dump.sql
BACKUP_FILE=/app/tmp/db_dump/phoenix-dump.sql.gz
AWS_BUCKET=phoenix-production-database-dump

echo `date` "Generating dump."
mysqldump -u $RDS_USERNAME -p$RDS_PASSWORD -h$RDS_HOSTNAME $RDS_DB_NAME > $BACKUP_FILE_RAW

echo `date` "Compressing dump."
gzip $BACKUP_FILE_RAW

echo `date` "Uploading dump to S3."
aws s3 cp $BACKUP_FILE s3://$AWS_BUCKET/

echo `date` "Deleting local dump file."
rm $BACKUP_FILE