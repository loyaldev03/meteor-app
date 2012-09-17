set :scm, :git
set :application, 'sac-platform'
set :cplatform, 'all'
set :deploy_to, "/var/www/#{application}"
set :repository, 'git@github.com:stoneacre/sac-platform.git'
set :database_name, 'sac_platform_production'
set :rails_env, "production"
set :user, 'deploy'

role :web, "50.116.20.46"

