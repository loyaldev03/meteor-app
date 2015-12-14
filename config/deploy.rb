# Do you want to put in mantainance mode the site during deployment?
# Use :
# cap -S put_in_maintenance_mode="true" prototype deploy
# cap -S elasticsearch_reindex="true" prototype deploy
# default value is false

set :stages, %w(production prototype staging demo prototype_pantheon staging_pantheon)
set :default_stage, "prototype"
default_run_options[:pty] = true
require 'capistrano/ext/multistage'
require 'bundler/capistrano'

set :port, 30003
set :term,                "linux"
set :deploy_via, :remote_cache
set :user, 'www-data'
set :use_sudo, false

set :branch, ENV['BRANCH'] if ENV['BRANCH']

# OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
# campfire access: stoneacreadmins / xagax2011
set :campfire_options, :account => 'stoneacreinc',
                       :room => 'Platform Room - General Discussion',
                       :token => 'b49ca8a3ba7d20f0e53fefb2d53915716b29e07f', 
                       :ssl => true

desc "Link config files."
task :link_config_files do
  puts "  * Creating shared symlinks... "
  run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  run "ln -nfs #{release_path}/doc #{release_path}/public/doc"
  #run "ln -nfs #{shared_path}/bundler #{release_path}/vendor/bundler"
  run "ln -nfs #{shared_path}/mes_account_updater_files #{release_path}/mes_account_updater_files"
  run "ln -nfs #{shared_path}/assets #{release_path}/public/assets"
  run "mkdir #{release_path}/tmp/cache; #{sudo} chown www-data:www-data #{release_path}/tmp/cache" if rails_env == "production"
  run "if [ -e #{release_path}/rake_task_runner ]; then chmod +x #{release_path}/rake_task_runner; fi"
end

desc "Creates a proper .env file."
task :envfile do
  run "echo RAILS_ENV=#{rails_env} >> #{release_path}/.env"
end

desc "Restart delayed jobs"
task :restart_delayed_jobs do
  run "#{sudo} service #{application} stop" 
  run "#{sudo} service #{application} start" 
end

namespace :elasticsearch do
  desc "start elasticsearch"
  task :start, :roles => :app, :except => { :no_release => true } do 
    run "#{sudo} service elasticsearch stop && #{sudo} service elasticsearch start" 
  end
  desc "stop elasticsearch"
  task :stop, :roles => :app, :except => { :no_release => true } do 
    run "#{sudo} service elasticsearch stop" 
  end
  desc "reindex the whole database"
  task :reindex, :roles => :app do
    run "cd #{current_path} && rake environment tire:import CLASS='User' FORCE=true"
  end
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
    run <<-EOF
      cd #{release_path} && 
      RAILS_ENV=#{stage} bundle exec rake db:migrate --trace
    EOF
  end
  # if you're still using the script/reaper helper you will need
  # these http://github.com/rails/irs_process_scripts

  # If you are using Passenger mod_rails uncomment this:
  task :restart, :roles => :web, :except => { :no_release => true } do
    run "touch #{File.join(release_path,'tmp','restart.txt')}"
    run "chmod 666 #{release_path}/log/*.log"
  end


  # taken from http://stackoverflow.com/questions/5735656
  task :tag do
    user = `git config --get user.name`.chomp
    email = `git config --get user.email`.chomp
    puts `git tag #{stage}_#{release_name} #{current_revision} -m "Deployed by #{user} <#{email}>"`
    puts `git push --tags origin`
  end
end

namespace :server_stats do
  desc "Tail the log from web." 
  task :log_web, :roles  => :web do
    stream "tail -f #{shared_path}/log/#{stage}.log" 
  end

  desc "Show Passenger status" 
  task :passenger, :roles => :web do
    run "#{sudo} passenger-status && #{sudo} passenger-memory-stats"
  end
end

namespace :customtasks do
  task :customcleanup, :except => {:no_release => true} do
    run "ls -1dt #{releases_path}/* | tail -n +#{keep_releases + 1} | #{sudo} xargs rm -rf"
  end
end

# taken from https://gist.github.com/1027117
namespace :foreman do
  desc "Export the Procfile to Ubuntu's upstart scripts"
  task :export, :roles => :web do
    run "cd #{release_path} && #{sudo} bundle exec foreman export upstart /etc/init -a #{application} -u www-data -l #{release_path}/log"
  end
  
  desc "Start the application services"
  task :start, :roles => :web do
    sudo "start #{application}"
  end

  desc "Stop the application services"
  task :stop, :roles => :web do
    sudo "stop #{application}"
  end

  desc "Restart the application services"
  task :restart, :roles => :web do
    run "start #{application} || restart #{application}"
  end
end

# taken from http://stackoverflow.com/questions/9016002/speed-up-assetsprecompile-with-rails-3-1-3-2-capistrano-deployment
task :assets, :roles => :web do
  run <<-EOF
    cd #{release_path} &&
    rm -rf public/assets &&
    mkdir -p #{shared_path}/assets &&
    ln -s #{shared_path}/assets public/assets &&
    export FROM=`[ -f #{current_path}/REVISION ] && (cat #{current_path}/REVISION | perl -pe 's/$/../')` &&
    export TO=`cat #{release_path}/REVISION` &&
    echo ${FROM}${TO} &&
    cd #{shared_path}/cached-copy &&
    git log ${FROM}${TO} --name-status -- app/assets vendor/assets | wc -l | egrep '^0$' ||
    (
      echo "Recompiling assets" &&
      cd #{release_path} &&
      RAILS_ENV=#{rails_env} bundle exec rake assets:precompile --trace
    )
  EOF
end

# mantainance_mode
namespace :maintenance_mode do
  desc "Start"
  task :start, :roles => :web do
    run "cd #{release_path} && RAILS_ENV=#{rails_env} bundle exec rake maintenance:start"
  end
  
  desc "Stop"
  task :stop, :roles => :web do
    run "cd #{release_path} && RAILS_ENV=#{rails_env} bundle exec rake maintenance:end"
  end
end

# after "deploy:setup", "deploy:db:setup" unless fetch(:skip_db_setup, false)
after "deploy:update_code", "link_config_files"
after "deploy:update_code", "assets"
after "deploy:update", "maintenance_mode:start" if fetch(:put_in_maintenance_mode, false)
after "deploy:update", "deploy:migrate"
after "deploy:update", "maintenance_mode:stop" if fetch(:put_in_maintenance_mode, false)
after 'deploy:update', 'restart_delayed_jobs'
after "deploy:update", "elasticsearch:reindex" if fetch(:elasticsearch_reindex, false)
after 'deploy', 'customtasks:customcleanup'
after "deploy", "deploy:tag"


