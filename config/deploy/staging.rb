set :scm, :git
set :application, 'staging.platform'
set :cplatform, 'all'
set :deploy_to, "/var/www/#{application}"
set :repository, 'git@github.com:stoneacre/sac-platform.git'
set :database_name, 'sac_platform_staging'
set :rails_env, "staging"
set :keep_releases,       3

server "staging.platform.xagax.com", :app, :web

task :bundle_install do
  puts "  **** bundle_install"
  run "id"
  run "cd #{release_path}; #{sudo} bundle install --without development test prototype"
end