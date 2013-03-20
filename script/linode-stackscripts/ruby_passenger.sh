#!/bin/bash
#
# Basic Linode setup for Ruby, Rails, Nginx and Passenger
# Author: Tim Cheadle (tim@rationalmeans.com)
#
# Does the following:
# - Installs and changes default editor to vim
# - Adds a user account
# - Adds the user to sudoers
# - Adds the user's public SSH key to ~/.ssh/authorized_keys
# - Secures SSHd config (passwordless, no root)
# - Edits hostname
# - Sets up firewall (ufwA)
# - Sets up Rails/Passenger/Nginx stack
#
# Includes and user-defined fields
#
# - User Security
#   http://www.linode.com/stackscripts/view/?StackScriptID=165
#
# <udf name="system_hostname" label="Hostname for system" default="" />
# <udf name="user_name" label="Unprivileged User Account" />
# <udf name="user_password" label="Unprivileged User Password" />
# <udf name="user_sshkey" label="Public Key for User" default="" />
# <udf name="sshd_port" label="SSH Port" default="30003" />
#
# - Ruby on Rails stack
#   (taken from http://www.linode.com/stackscripts/view/?StackScriptID=2438)
#
# <udf name="r_env" Label="Rails/Rack environment to run" default="production" />
# <udf name="ruby_release" Label="Ruby Version" default="1.9.3-p385" example="1.9.3-p385" />
# <udf name="deploy_user" Label="Name of deployment user" default="deploy" />
# <udf name="deploy_password" Label="Password for deployment user" />
# <udf name="deploy_sshkey" Label="Deployment user public ssh key" />

source <ssinclude StackScriptID=1>    # Common bash functions
source <ssinclude StackScriptID=123>  # Awesome ubuntu utils script

function log {
  echo "### $1 -- `date '+%D %T'`" | tee -a /root/stackscript.log
}

function set_nginx_boot_up {
  wget http://pastebin.com/download.php?i=bh7xJ328 -O nginx
  chmod 744 /etc/init.d/nginx
  /usr/sbin/update-rc.d -f nginx defaults
  cat > /etc/logrotate.d/nginx << EOF
/usr/local/nginx/logs/* {
  daily
  missingok
  rotate 52
  compress
  delaycompress
  notifempty
  create 640 nobody root
  sharedscripts
  postrotate
  [ ! -f /user/local/nginx/logs/nginx.pid ] || kill -USR1 `cat /user/local/logs/nginx.pid`
  endscript
}
EOF
}

function set_production_gemrc {
  cat > ~/.gemrc << EOF
verbose: true
bulk_treshold: 1000
install: --no-ri --no-rdoc
benchmark: false
backtrace: false
update: --no-ri --no-rdoc
update_sources: true
EOF
  cp ~/.gemrc $USER_HOME
  chown $USER_NAME:$USER_NAME $USER_HOME/.gemrc
}


log "Updating System..."
system_update


log "Setting up wget, vim, less, git"
aptitude -y install wget vim less git-core


log "Setting hostname to $SYSTEM_HOSTNAME"
system_update_hostname $SYSTEM_HOSTNAME


log "Setting basic security settings"
aptitude -y install fail2ban ufw
ufw logging on
ufw default deny
ufw allow $SSHD_PORT/tcp
ufw limit $SSHD_PORT/tcp
ufw allow http/tcp
ufw allow https/tcp
ufw enable


log "Setting up sshd security settings"
system_sshd_permitrootlogin No
system_sshd_passwordauthentication No
system_sshd_pubkeyauthentication Yes
sed -i "s/^#*Port .*/Port 30003/" /etc/ssh/sshd_config
service ssh restart


log "Setting up sudo"
aptitude -y install sudo
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers


log "Creating unprivileged user"
USER_NAME_LOWER=`echo ${USER_NAME} | tr '[:upper:]' '[:lower:]'`
useradd -m -s /bin/bash -G sudo ${USER_NAME_LOWER}
echo "${USER_NAME_LOWER}:${USER_PASSWORD}" | chpasswd

USER_HOME=`sed -n "s/${USER_NAME_LOWER}:x:[0-9]*:[0-9]*:[^:]*:\(.*\):.*/\1/p" < /etc/passwd`

sudo -u ${USER_NAME_LOWER} mkdir ${USER_HOME}/.ssh
echo "${USER_SSHKEY}" >> $USER_HOME/.ssh/authorized_keys
chmod 0600 $USER_HOME/.ssh/authorized_keys
chown ${USER_NAME_LOWER}:${USER_NAME_LOWER} $USER_HOME/.ssh/authorized_keys



log "Creating deployment user $DEPLOY_USER"
system_add_user $DEPLOY_USER $DEPLOY_PASSWORD "users,sudo"
system_user_add_ssh_key $DEPLOY_USER "$DEPLOY_SSHKEY"
system_update_locale_en_US_UTF_8
cat >> /etc/sudoers <<EOF
Defaults !secure_path
$DEPLOY_USER ALL=(ALL) NOPASSWD: ALL
EOF


log "installing logrotate"
apt-get -y install logrotate


log "Installing nginx"
aptitude -y install python-software-properties
add-apt-repository ppa:nginx/stable
apt-get update
apt-get upgrade --show-upgraded
aptitude -y install nginx


log "Installing rbenv system-wide"
git clone git://github.com/sstephenson/rbenv.git /usr/local/rbenv
echo '# rbenv setup' > /etc/profile.d/rbenv.sh
echo 'export RBENV_ROOT=/usr/local/rbenv' >> /etc/profile.d/rbenv.sh
echo 'export PATH="$RBENV_ROOT/bin:$PATH"' >> /etc/profile.d/rbenv.sh
echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh
chmod +x /etc/profile.d/rbenv.sh
source /etc/profile.d/rbenv.sh


log "Installing ruby-build"
pushd /tmp
  git clone git://github.com/sstephenson/ruby-build.git
  cd ruby-build
  ./install.sh
popd

log "Installing Ruby $RUBY_VERSION"
rbenv install $RUBY_VERSION
rbenv global $RUBY_VERSION


log "Updating Ruby gems"
set_production_gemrc
gem update --system


log "Instaling Phusion Passenger and Nginx"
gem install passenger
passenger-install-nginx-module --auto --auto-download --prefix="/usr/local/nginx"


#log "Setting up Nginx to start on boot and rotate logs"
#set_nginx_boot_up


log "Setting Rails/Rack defaults"
cat >> /etc/environment << EOF
RAILS_ENV=$R_ENV
RACK_ENV=$R_ENV
EOF


log "Install Bundler"
gem install bundler


log "Restarting Services"
restart_services
