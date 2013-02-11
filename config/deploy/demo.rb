set :scm, :git
set :application, 'sac-platform'
set :cplatform, 'all'
set :deploy_to, "/var/www/#{application}"
set :repository, 'git@github.com:stoneacre/sac-platform.git'
set :database_name, 'sac_platform_demo'
set :rails_env, "demo"
set :user, 'deploy'

server "50.116.20.46", :app, :web

# taken from https://rvm.io/integration/capistrano/ && http://stackoverflow.com/questions/8003762/rvmsudo-does-not-work-in-deploy-rb-on-ubuntu
$:.unshift(File.expand_path('./lib', ENV['rvm_path']))
require 'rvm/capistrano'
set :rvm_type, :system 
set :rvm_ruby_string, '1.9.3-p194@sac-platform-rails3' 
set :rvm_bin_path, "/usr/local/rvm/bin"
set :sudo, 'rvmsudo'
