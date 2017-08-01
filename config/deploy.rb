lock "3.8.0"
set :stages,        %w(production prototype staging)
set :pty,           'true'
set :term,          "linux"
set :user,          'deploy'
set :use_sudo,      false
set :branch,        ENV['BRANCH'] if ENV['BRANCH']
set :ssh_options, {
  forward_agent: true,
  port: 30003
}

set :linked_dirs,   fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/files', 'tmp/sockets', 'vendor/bundle', 'public/system', 'public/doc', 'doc')
set :linked_files,  fetch(:linked_files, []).push('config/database.yml')

namespace :deploy do
  desc "Restart application and Delayed Jobs"
  task :restart do
    on roles(:app) do
      sudo :service, fetch(:application), :stop 
      sudo :service, fetch(:application), :start 
      execute :touch, current_path.join("tmp/restart.txt")
    end
  end
  
  desc "Copy mainteannce.yml file to make sure app is in maintenance mode if needed."
  task :copy_maintenance_file do
    on roles(:app) do
      info "Copying maintenance.yml file from shared to current path"
      execute "if [ -e #{shared_path}/tmp/maintenance.yml ]; then cp #{shared_path}/tmp/maintenance.yml #{current_path}/tmp/; fi"
    end
  end
  
  # taken from http://stackoverflow.com/questions/5735656
  task :tag do
    on roles(:app) do
      if fetch(:rails_env) == 'production'
        user = `git config --get user.name`.chomp
        email = `git config --get user.email`.chomp
        tag_name = "#{fetch(:stage)}_#{fetch(:release_timestamp)}"
        puts `git tag #{tag_name} -m "Deployed by #{user} <#{email}>"`
        puts `git push origin #{tag_name}`
      else
        info "No new tag created for #{fetch(:rails_env)}."
      end
    end
  end

  desc 'Start maintenance mode'
  task :enable_maintenance_mode do
    on roles(:app) do
      puts "Starting maintenance mode"
      execute "cd #{current_path} && #{fetch(:rvm_custom_path)}/bin/rvm #{fetch(:rvm_ruby_version)} do bundle exec rake maintenance:start"
      execute "mkdir -p '#{shared_path}/tmp/' && cp #{current_path}/tmp/maintenance.yml #{shared_path}/tmp/"
    end
  end

  desc 'End maintenance mode'
  task :disable_maintenance_mode do
    on roles(:app) do
      puts "Ending maintenance mode"
      execute "cd #{current_path} && #{fetch(:rvm_custom_path)}/bin/rvm #{fetch(:rvm_ruby_version)} do bundle exec rake maintenance:end"
      execute "rm '#{shared_path}/tmp/maintenance.yml'"
    end
  end
end

after 'deploy:published', 'deploy:copy_maintenance_file'
after 'deploy', 'deploy:restart'
after 'deploy', 'deploy:tag'