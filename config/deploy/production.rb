server "50.116.20.46", user: 'deploy', roles: [:app, :web, :db]

set :application,      'sac-platform'
set :cplatform,        'all'
set :deploy_to,        "/var/www/#{fetch(:application)}"
set :repo_url,         'git@github.com:stoneacre/sac-platform.git'
set :database_name,    'sac_production'
set :rails_env,        "production"
set :keep_releases,    5
set :rvm_type,         :system 
set :rvm_ruby_version, '2.4.2@global'
set :rvm_custom_path,  '/usr/local/rvm'
set :sudo,             'rvmsudo'