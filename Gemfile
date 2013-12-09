source 'https://rubygems.org'

gem 'active_shipping', :path => '../active_shipping'
# gem 'active_shipping', '0.9.13.6.copious'
gem 'activemerchant'
#gem 'activevalidators', '1.9.0.3.copious'
gem 'activevalidators', :path => '../activevalidators'
gem 'acts_as_list', '>= 0.1.8'
gem 'airbrake'
#gem 'anchor', '>= 1.4.0'
gem 'anchor', path: '../anchor/client'
gem 'attribute_normalizer', '>= 1.1.0'
gem 'backbone-rails'
#gem 'balanced', '0.3.11.copious.1'
gem 'balanced', path: '../balanced-ruby'
gem 'bartt-ssl_requirement', :require => 'ssl_requirement'
gem 'bcrypt-ruby', :require => 'bcrypt'
gem 'bootstrap-datepicker-rails'
#gem 'bootstrap-slider-rails', '~> 2.0.0.2'
gem 'bootstrap-slider-rails', path: '../bootstrap-slider-rails'
#gem 'bootstrap-sass', path: "../bootstrap-sass"
gem 'bootstrap-sass', '2.3.0.0'
gem 'bson_ext'
gem 'cancan'
gem 'carmen', '1.0.0.beta2'
gem 'carmen-rails'
#gem 'carrierwave', '0.5.8.copious.2'
gem 'carrierwave', path: '../carrierwave'
gem 'crack', '~> 0.3.2' # webmock
gem 'faraday', '~> 0.8.4'
gem 'faraday_middleware', '~> 0.9.0'
#gem 'flyingdog', '>= 3.0.0'
gem 'flyingdog', path: '../flyingdog/client'
gem 'fog'
gem 'foreigner', '1.2.1'
gem 'handlebars_assets'
gem 'log_weasel', path: '../log_weasel'
gem 'httparty', '~> 0.10.0' # mogli, hipchat, httpmultiparty
gem 'jquery-rails'
gem 'jsend-rails', '~> 1.0.0'
#gem 'jsend-rails', path: '../jsend-rails'
gem 'kaminari'
#gem 'ladon', '>= 4.3.0'
gem 'ladon', :path => '../ladon'
#gem 'lagunitas', '>= 2.7.0'
gem 'lagunitas', path: '../lagunitas/client'
#gem 'risingtide', '~> 0.6.0'
gem 'risingtide', path: '../risingtide/client'
gem 'mime-types'
gem 'modernizr_rails', :require => 'modernizr-rails'
gem 'mogli', path: '../mogli'
gem 'multi_json', '~> 1.0.4'
gem 'mysql2'
gem 'omniauth-facebook'
gem 'omniauth-twitter'
gem 'omniauth-tumblr', '~> 1.1'
gem 'omniauth-instagram'
gem 'instagram', path: '../instagram-ruby-gem'
gem 'progress_bar'
#gem 'pyramid', '2.0.0'
gem 'pyramid', path: '../pyramid'
gem 'rack', '~> 1.3.10' # security release
#gem 'rack-multipart_related', '0.2.0.copious.1'
gem 'rack-multipart_related', path: '../rack-multipart_related'
#gem 'rack-oauth2', '0.14.4.copious.1'
gem 'rack-oauth2', path: '../rack-oauth2'
gem 'rails', '3.1.12' # security release
#gem 'redhook', '~> 2.0.0'
gem 'redhook', :path => '../redhook/client'
gem 'redis-objects'
gem 'resque', '~> 1.23'
gem 'resque-pool', :require => false
gem 'resque-retry', :require => false
gem 'resque-scheduler', :require => false
gem 'rmagick'
gem 'rpx_now'
#gem 'rubicon', '~> 2.1.0'
gem 'rubicon', path: '../rubicon/client'
gem 'sass', '~> 3.2.0'
gem 'seed-fu'
gem 'sendgrid'
gem 'session_off'
#gem 'stamps', '>= 0.2.0.copious.7'
gem 'stamps', path: '../stamps'
gem 'state_machine'
gem 'sunspot_rails', '1.3.0'
gem 'SyslogLogger', '~> 2.0', require: false
gem 'thor'
gem 'typhoeus', '0.2.4.2.copious'
#gem 'typhoeus', path: '../typhoeus'
#gem 'vanity', '1.8.0.copious.1'
gem 'vanity', path: '../vanity'
gem 'viva-app_config'
gem 'weighted_randomizer'
gem "recaptcha", :require => "recaptcha/rails"

# needed only in development environments (for deployment)
group :development do
  gem 'capistrano'
  gem 'capistrano-ext'
  gem 'capistrano-deploytags'
  gem 'foreman', '0.26.1'
  gem 'hipchat'
  gem 'sunspot_solr', '1.3.0'
  gem 'thin'
  gem 'mailcatcher'
  gem 'xray-rails'
end

# needed only in development, test and integration environments
group :development, :test, :integration do
  gem 'capybara'
  gem 'database_cleaner'
  gem 'factory_girl_rails'
  gem 'growl'
  gem 'guard'
  gem 'guard-rspec'
  gem 'guard'
  gem 'launchy', :require => false
  gem 'mocha', '~> 0.13.2', require: false
  gem 'mongo'
  gem 'rb-fsevent'
  gem 'rcov'
  gem 'rspec-rails', '~> 2.12.2'
  gem 'spork', '0.9.0.rc9'
  gem 'timecop', :require => false
  gem 'license_finder', :git => "https://github.com/utahstreetlabs/LicenseFinder.git"
  gem 'ruby-graphviz', :require => 'graphviz'
  gem 'parallel_tests'
  gem 'webmock', :require => false
  gem 'selenium-webdriver', '~> 2.32.0'
  gem 'growl-rspec'
  # seriously, fuck this shit: https://gist.github.com/1331533
  if ENV['BROOKLYN_DEBUG']
    gem 'ruby-debug19'
    gem 'ruby-debug-base19'
  end
  gem 'awesome_print'
  gem 'chromedriver-helper'
  gem 'rails-dev-tweaks', '~> 0.6.1'
  gem 'konacha'
  gem 'chai-jquery-rails'
  gem 'sinon-rails'
  gem 'sinon-chai-rails'
  gem 'useragent'
  gem 'ga_cookie_parser'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   "~> 3.1.0"
  gem 'coffee-rails', '~> 3.1.0'
  gem 'uglifier'
  gem 'therubyracer'
  gem 'asset_sync'
end
