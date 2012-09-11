set :scm, :git
set :application, 'backend-sac-platform'
set :cplatform, 'all'
set :deploy_to, "/var/www/#{application}"
set :repository, 'git@github.com:stoneacre/sac-platform.git'
set :database_name, 'sac_platform_prototype'
set :rails_env, "prototype"

role :web, "prototype.platform.xagax.com"

