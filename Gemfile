source 'http://rubygems.org'

gem 'rails', '4.2.6'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'mysql2', '0.4.5'
gem 'uuidtools'

gem "paperclip", "~> 3.0"
gem 'aws-sdk', '< 2.0'

gem 'acts_as_list'
gem 'delayed_job_active_record'
gem "delayed_job_web" # FIXME it is not working in rails 4
# uncomment if pardot is enabled again
# gem "ruby-pardot"

gem 'json', '1.8.3'

gem 'turnout'
gem 'exact_target_sdk', github: 'daws/exact_target_sdk'
gem 'gibbon', github: 'amro/gibbon'
gem 'mandrill-api'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails'
  gem 'coffee-rails'
  gem 'uglifier'
end


gem 'jquery-ui-rails'
gem 'jquery-datatables', github: 'sebastianGitDL/jquery-datatables'

gem 'carmen-rails'
gem 'country_code_select', '~> 1.0.0'
gem 'i18n-country-translations'
gem 'devise'
gem 'devise-async'
gem 'devise-encryptable'
gem 'settingslogic', '2.0.8'
gem 'wirble'
gem 'bootstrap-will_paginate'
gem 'nokogiri'
gem 'faraday', '>= 0.9.1'
gem 'faraday_middleware', '>= 0.9.0'
gem 'hashie'
gem 'state_machine', '1.1.2'
gem 'cancan'
gem 'easy_roles'
gem "axlsx", "~> 2.0.1"

gem 'twitter-bootstrap-rails', '2.2.7'

gem 'jquery-rails'

gem "paranoia", "~> 2.0"
gem 'exception_notification', github: 'stoneacre/exception_notification'
gem 'pivotal-tracker'

gem "newrelic_rpm"
gem 'premailer-rails'
gem "enum_help"
gem "fb_graph2"
gem "select2-rails"

gem 'rack-cors'
gem 'minitest', '~>5.1'
gem 'friendly_id', '~> 5.1.0'
gem 'daemons'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# To use debugger
group :development do
  gem "rails-erd"
  gem 'rack-bug', :git => 'https://github.com/brynary/rack-bug.git', :branch => 'rails3'
  gem "yard"  , :git => 'git://github.com/stoneacre/yard.git'
  gem 'yard-rest'
  gem 'redcarpet'
  gem 'ruby-prof'
  # -> deploy
  gem 'capistrano', '2.15.4'
  gem 'rvm-capistrano',  require: false
  gem 'tinder'
  #####
  gem 'foreman'
  gem 'quiet_assets'
  gem 'mailcatcher', require: false
end

gem 'tire'
gem 'progress_bar'
gem 'data-confirm-modal', github: 'ifad/data-confirm-modal', branch: 'bootstrap2'
gem 'fat_fingers', github: 'dmferrari/fat_fingers'

group :test do
  gem 'factory_girl_rails'
  gem 'faker', github: 'stympy/faker'
  gem 'mocha', require: false
  gem 'capybara'
  gem 'selenium-webdriver', '>=2.53.0'
  gem 'brakeman'
  gem 'simplecov'
  gem "timecop"
  gem 'connection_pool'
end

group :test, :development do
  gem 'byebug'
end

gem 'activemerchant'
gem 'LitleOnline', '8.16.0'

# TODO => remove the following requires after tokenization is implemented
### only for Auth.Net  without tokenization.
gem 'encryptor'
###################

gem 'bureaucrat'
gem 'rake', '10.4.2'
gem 'validates_timeliness', '~> 4.0'
gem 'request_store'
