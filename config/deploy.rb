set :stages, %w(production staging)
set :default_stage, "staging"
require 'capistrano/ext/multistage'

set :port, 30003
set :keep_releases,       2
set :term,                "linux"
set :deploy_via, :remote_cache
set :user, 'www-data'
set :use_sudo, false


OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
# campfire access: stoneacreadmins / xagax2011
set :campfire_options, :account => 'stoneacreinc',
                       :room => 'Platform Room - General Discussion',
                       :token => 'b49ca8a3ba7d20f0e53fefb2d53915716b29e07f', 
                       :ssl => true

desc "Link config files."
task :link_config_files do
  run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  run "ln -nfs #{release_path}/doc #{release_path}/public/doc"
  run "if [ -e #{release_path}/rake_task_runner ]; then chmod +x #{release_path}/rake_task_runner; fi"
end

task :bundle_install do
  run "cd #{release_path}; bundle install"
end

desc "Restart delayed jobs"
task :restart_delayed_jobs do
  run "/opt/ruby-enterprise-1.8.7-2011.03/bin/god restart #{application}-dj" 
  campfire_room.speak "#{cplatform} #{application} (#{scm_username}): deployed branch "
end

namespace :deploy do
  namespace :db do
    desc <<-DESC
      Creates the database.yml configuration file in shared path.

      By default, this task uses a template unless a template \
      called database.yml.erb is found either is :template_dir \
      or /config/deploy folders. The default template matches \
      the template for config/database.yml file shipped with Rails.

      When this recipe is loaded, db:setup is automatically configured \
      to be invoked after deploy:setup. You can skip this task setting \
      the variable :skip_db_setup to true. This is especially useful \ 
      if you are using this recipe in combination with \
      capistrano-ext/multistaging to avoid multiple db:setup calls \ 
      when running deploy:setup for all stages one by one.
    DESC
    task :setup, :except => { :no_release => true } do
      default_template = <<-EOF
  #{stage}:
  adapter: mysql2
  encoding: utf8
  database: #{database_name}
  username: root   
  password: f4c0n911
  host: 127.0.0.1
  port: 3306
      EOF

      location = fetch(:template_dir, "config/deploy") + '/database.yml.erb'
      template = File.file?(location) ? File.read(location) : default_template

      config = ERB.new(template)

      run "mkdir -p #{shared_path}/db" 
      run "mkdir -p #{shared_path}/config" 
      put config.result(binding), "#{shared_path}/config/database.yml"
    end
  end

  task :migrate, :roles => :web, :except => { :no_release => true } do
    run "cd #{release_path}; RAILS_ENV='#{stage}' rake db:migrate --trace"
  end
  # if you're still using the script/reaper helper you will need
  # these http://github.com/rails/irs_process_scripts

  # If you are using Passenger mod_rails uncomment this:
  task :restart, :roles => :web, :except => { :no_release => true } do
    run "touch #{File.join(release_path,'tmp','restart.txt')}"
    run "chmod 666 #{release_path}/log/*.log"
  end

  # desc "Compile assets"
  # task :compile_assets, :roles => :web do 
  #   run "cd #{current_path}; bundle exec rake assets:precompile"
  # end  
end

namespace :server_stats do
  desc "Tail the log from web." 
  task :log_web, :roles  => :web do
    stream "tail -f #{shared_path}/log/#{stage}.log" 
  end
end


after "deploy:setup", "deploy:db:setup"   unless fetch(:skip_db_setup, false)
before "deploy:assets:precompile", "link_config_files", # "bundle_install", "deploy:migrate" 
