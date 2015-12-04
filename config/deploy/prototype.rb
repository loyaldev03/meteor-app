set :scm, :git
set :application, 'backend-sac-platform'
set :cplatform, 'all'
set :deploy_to, "/var/www/#{application}"
set :repository, 'git@github.com:stoneacre/sac-platform.git'
set :database_name, 'sac_platform_prototype'
set :rails_env, "prototype"
set :keep_releases,       3

server "prototype.platform.xagax.com", :app, :web

set :rvm_type, :system 
set :rvm_ruby_string, '2.2.0@global' 
require 'rvm/capistrano'
set :rvm_bin_path, "/usr/local/rvm/bin"
set :sudo, 'rvmsudo'

