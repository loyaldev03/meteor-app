set :scm, :git
set :application, 'staging.platform'
set :cplatform, 'all'
set :deploy_to, "/var/www/#{application}"
set :repository, 'git@github.com:stoneacre/sac-platform.git'
set :database_name, 'sac_platform_staging'
set :rails_env, "staging"
set :keep_releases,       3

server "staging.platform.xagax.com", :app, :web

set :rvm_type, :system 
set :rvm_ruby_string, '1.9.3-p327' 
require 'rvm/capistrano'
set :rvm_bin_path, "/usr/local/rvm/bin"
set :sudo, 'rvmsudo'

