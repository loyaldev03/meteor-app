set :scm, :git
set :application, 'staging.platform'
set :cplatform, 'all'
set :deploy_to, "/var/www/#{application}"
set :repository, 'git@github.com:stoneacre/sac-platform.git'
set :database_name, 'sac_platform_staging'
set :rails_env, "staging"

server "staging.platform.xagax.com", :app, :web

