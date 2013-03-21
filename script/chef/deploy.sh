#!/bin/bash

# Usage: ./deploy.sh [IP-address] [host] <domain>
#   <domain> defaults to stoneacreinc.com
#
# Example: ./deploy.sh 172.16.254.1 foobar example.com

ip="${1}"
host="${2}"
domain="${3}"

if [ "x$ip" == "x" -o "x$host" == "x" ]; then
  echo "Usage: deploy.sh [ip] [hostname] <domain>" >&2
  exit 1
fi

if [ "x$domain" == "x" ]; then
  domain='stoneacreinc.com'
fi

fqdn="${host}.${domain}"
remote="root@${ip}"

# The host key might change when we instantiate a new VM, so
# we remove (-R) the old host key from known_hosts
ssh-keygen -R "${fqdn#*@}" 2> /dev/null
ssh-keygen -R "${ip#*@}" 2> /dev/null

# production
tar cj . | ssh -o "StrictHostKeyChecking no" "${remote}" "
rm -rf /var/chef &&
mkdir /var/chef &&
cd /var/chef &&
tar xj &&
bash install.sh \"${ip}\" \"${host}\" \"${domain}\""
