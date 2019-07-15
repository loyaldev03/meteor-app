#!/bin/sh
echo "ENTERED ENTRYPOINT"
# https://stackoverflow.com/a/38732187/1935918
set -e

# Setup AWS CLI
ROLENAME=$(curl http://169.254.169.254/latest/meta-data/iam/security-credentials/ -s)
KeyURL="http://169.254.169.254/latest/meta-data/iam/security-credentials/"$ROLENAME"/"
wget $KeyURL -q -O Iam.json
aws_access_key_id=$(grep -Po '.*"AccessKeyId".*' Iam.json | sed 's/ //g' | sed 's/"//g' | sed 's/,//g' | sed 's/AccessKeyId://g')
aws_access_key_id=$(grep -Po '.*"SecretAccessKey".*' Iam.json | sed 's/ //g' | sed 's/"//g' | sed 's/,//g' | sed 's/SecretAccessKey://g')
security_token=$(grep -Po '.*"Token".*' Iam.json | sed 's/ //g' | sed 's/"//g' | sed 's/,//g' | sed 's/Token://g')
rm Iam.json -f

export AWS_ACCESS_KEY_ID=${aws_access_key_id}
export AWS_SECRET_ACCESS_KEY=${aws_access_key_id}
export AWS_ACCESS_TOKEN=${security_token}

if [ -f /app/tmp/pids/server.pid ]; then
  rm /app/tmp/pids/server.pid
fi

bundle exec rake db:migrate 2>/dev/null || bundle exec rake db:setup

exec bundle exec "$@"
