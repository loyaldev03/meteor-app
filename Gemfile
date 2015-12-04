source 'http://rubygems.org'

gem 'rails', '4.2.3'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'mysql2', '~> 0.3.18'
gem 'uuidtools'

gem "paperclip", "~> 3.0"

gem 'acts_as_list', "0.7.2"
gem 'delayed_job_active_record'
gem "delayed_job_web" # FIXME it is not working in rails 4 
# uncomment if pardot is enabled again
# gem "ruby-pardot"

gem 'json', '1.8.3'

gem 'turnout'
gem 'exact_target_sdk', github: 'daws/exact_target_sdk'
gem 'gibbon'
gem 'mandrill-api'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails'
  gem 'coffee-rails'
  gem 'uglifier'
end


gem 'jquery-datatables-rails', github: 'rweng/jquery-datatables-rails'
gem 'jquery-ui-rails'

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
gem 'faraday', '0.8.5'
gem 'faraday_middleware', '0.9.0'
gem 'hashie'
gem 'state_machine', '1.1.2'
gem 'cancan'
gem 'easy_roles'
gem "axlsx", "~> 2.0.1"

gem 'twitter-bootstrap-rails', '2.2.7'

gem 'jquery-rails'

gem "paranoia", "~> 2.0"

#gem "airbrake"
gem "zendesk_api"


# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

gem 'oboe'

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
  gem 'capistrano-campfire', '0.2.0'
  gem 'tinder'
  #####
  gem 'daemons'
  gem 'foreman'
  gem 'quiet_assets'
  gem "bullet", '4.6.0'
end

gem 'tire'
gem 'progress_bar'

group :test do
  gem 'factory_girl_rails'
  gem 'faker'
  gem 'mocha', require: false
  gem 'capybara'
  gem 'selenium-webdriver', '>=2.45.0'
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

gem 'protected_attributes' # TODO: remove this gem after upgrading
