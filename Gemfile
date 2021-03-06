source 'http://rubygems.org'

gem 'rails', '4.2.10'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'mysql2', '0.4.5'
gem 'uuidtools'

gem 'paperclip', '~> 5.1.0'
gem 'aws-sdk', '~> 2.10.0'

gem 'acts_as_list'
gem 'delayed_job_active_record', '~> 4.1', '>= 4.1.3'
gem "delayed_job_web" # FIXME it is not working in rails 4
# uncomment if pardot is enabled again
# gem "ruby-pardot"

gem 'json'

gem 'turnout'
gem 'exact_target_sdk', github: 'daws/exact_target_sdk'
gem 'gibbon', github: 'amro/gibbon'
gem 'mandrill-api'

gem 'puma'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails'
  gem 'coffee-rails'
  gem 'uglifier'
end


gem 'jquery-ui-rails', '6.0.1'
gem 'jquery-datatables', github: 'sebastianGitDL/jquery-datatables'

gem 'carmen-rails'
#gem 'country_code_select', '~> 1.0.0'
gem 'i18n-country-translations'
gem 'devise'
gem 'devise-async'
gem 'devise-encryptable'
gem 'settingslogic', '2.0.8'
gem 'wirble'
gem 'bootstrap-will_paginate'
gem 'nokogiri', '1.8.3'
gem 'faraday', '>= 0.9.1'
gem 'faraday_middleware', '>= 0.9.0'
gem 'net-sftp', require: false
gem 'hashie'
gem 'state_machine', '1.1.2'
gem 'cancan'
gem 'easy_roles'
gem "axlsx", '3.0.0.pre'
gem 'simple_xlsx_reader'

gem 'twitter-bootstrap-rails', '2.2.7'

gem 'jquery-rails', '4.3.3'

gem "paranoia", "~> 2.0"
gem 'exception_notification', github: 'stoneacre/exception_notification'
gem 'tracker_api'

gem "newrelic_rpm"
gem 'premailer-rails'
gem "enum_help"
gem "fb_graph2"
gem "select2-rails"

gem 'rack-cors'
gem 'minitest', '~>5.1'
gem 'friendly_id', '~> 5.1.0'
gem 'daemons', '1.1.9'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# To use debugger
group :development do
  gem "rails-erd"
  gem "yard"  , :git => 'git://github.com/stoneacre/yard.git'
  gem 'yard-rest'
  gem 'redcarpet'
  gem 'ruby-prof'
  # -> deploy
  gem "capistrano", "3.8.0"
  gem 'capistrano-rails', '1.3'
  gem 'capistrano-rvm'
  gem 'tinder', '~>1.10'
  #####
  gem 'foreman'
  gem 'quiet_assets'
  # gem 'mailcatcher', require: false
end

gem 'tire'
gem 'progress_bar'
gem 'data-confirm-modal', github: 'ifad/data-confirm-modal', branch: 'bootstrap2'
gem 'mailcheck', github: 'dmferrari/mailcheck-ruby'

group :test do 
  gem 'factory_bot_rails', '~> 4.11'
  gem 'faker'
  gem 'mocha', require: false
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'brakeman'
  gem 'simplecov'
  gem "timecop"
  gem 'connection_pool'
end

group :test, :development do
  gem 'byebug'
end

gem 'activemerchant', github: 'sebastianGitDL/active_merchant', branch: 'payeezy-level2-data'
gem 'LitleOnline', '8.16.0'
gem 'ruby-gmail'
gem 'rollbar'

# TODO => remove the following requires after tokenization is implemented
### only for Auth.Net  without tokenization.
gem 'encryptor'
###################

gem 'bureaucrat'
gem 'rake', '10.4.2'
gem 'validates_timeliness', '~> 4.0'
gem 'request_store'
