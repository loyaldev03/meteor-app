#!/bin/bash

# Usage: ./install.sh [IP-address] [host] <domain>
#   <domain> defaults to stoneacreinc.com
#
# Example: ./install.sh 172.16.254.1 foobar example.com
#
# This has to run as root on the server

ip="${1}"
host="${2}"
domain="${3}"

echo "ip: $ip"
echo "host: $host"

if [ "x$ip" == "x" -o "x$host" == "x" ]; then
  echo "Usage: install.sh [ip] [hostname] <domain>" >&2
  exit 1
fi

if [ "x$domain" == "x" ]; then
  domain='stoneacreinc.com'
fi

fqdn="${host}.${domain}"
remote="root@${fqdn}"

chef_binary="/usr/local/bin/chef-solo"
ruby_release="1.9.3-p385"  # must be 1.9.x

if [[ ! -f "json/${host}/solo.json" ]]; then
  json_file="json/default/solo.json";
else
  json_file="json/${host}/solo.json";
fi

# Are we on a vanilla system?
if ! test -f "${chef_binary}"; then
  # update system
  apt-get update
  apt-get -y install aptitude
  aptitude -y full-upgrade

  # set hostname
  echo "${host}" > /etc/hostname
  hostname -F /etc/hostname

  # update /etc/hosts:
  echo "${ip} ${fqdn} ${host}" >> /etc/hosts

  # set the timezone
  ln -sf /usr/share/zoneinfo/Etc/GMT /etc/localtime

  # set locale
  locale-gen en_US.UTF-8
  /usr/sbin/update-locale LANG=en_US.UTF-8

  ### install base packages
  aptitude -y install build-essential zlib1g-dev libssl-dev libreadline-dev libyaml-dev libcurl4-openssl-dev curl python-software-properties wget

  # install ruby
  mkdir /tmp/src && cd /tmp/src
  curl -LO http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-${ruby_release}.tar.gz
  tar -xvzf ruby-${ruby_release}.tar.gz
  cd ruby-${ruby_release}/
  ./configure --prefix=/usr/local
  make
  make install

  # install chef
  gem install chef ruby-shadow --no-ri --no-rdoc

  # set up firewall
  aptitude -y install fail2ban ufw
  ufw logging on
  ufw default deny
  ufw allow $SSHD_PORT/tcp
  ufw limit $SSHD_PORT/tcp
  ufw enable
fi &&

cd /var/chef &&

"${chef_binary}" --color --log_level debug -c solo.rb -j "${json_file}"
