server "prototype.platform.xagax.com", user: 'deploy', roles: [:app, :web]

set :application,      'backend-sac-platform'
set :cplatform,        'all'
set :deploy_to,        "/var/www/#{fetch(:application)}"
set :repo_url,         'git@github.com:stoneacre/sac-platform.git'
set :database_name,    'sac_platform_prototype'
set :rails_env,        "prototype"
set :keep_releases,    3
set :rvm_type,         :system 
set :rvm_ruby_version, '2.2.0@global'
set :rvm_custom_path,  '/usr/local/rvm'
set :sudo,             'rvmsudo'