set :scm, :git
set :application, 'sac-platform-demo'
set :cplatform, 'all'
set :deploy_to, "/var/www/#{application}"
set :repository, 'git@github.com:stoneacre/sac-platform.git'
set :database_name, 'sac_platform_demo'
set :rails_env, "demo"
set :user, 'deploy'

server "96.126.126.56", :app, :web

# taken from https://rvm.io/integration/capistrano/ && http://stackoverflow.com/questions/8003762/rvmsudo-does-not-work-in-deploy-rb-on-ubuntu
# $:.unshift(File.expand_path('./lib', ENV['rvm_path'])) # commented this line because it loads another file

task :bundle_install do
  puts "  **** bundle_install"
  run "id"
  run "cd #{release_path}; #{sudo} bundle install --without development test prototype staging"
end

set :rvm_type, :system 
set :rvm_ruby_string, '1.9.3-p194@sac-platform-rails3' 

require 'rvm/capistrano'

set :rvm_bin_path, "/usr/local/rvm/bin"
set :sudo, 'rvmsudo'

