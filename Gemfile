source "https://rubygems.org"

ruby "2.1.2"

gem "active_model_serializers"
gem "angularjs-rails"
gem "bourbon"
gem "coffee-rails"
gem "dalli"
gem "faraday-http-cache"
gem "font-awesome-rails"
gem "haml-rails"
gem "high_voltage"
gem "jquery-rails"
gem "neat"
gem "newrelic_rpm"
gem "octokit"
gem "omniauth-github"
gem "paranoia", "~> 2.0"
gem "pg"
gem "rails", "4.0.4"
gem "resque", "~> 1.22.0"
gem "resque-retry"
gem "rubocop", "0.24.1"
gem "sass-rails", "~> 4.0.2"
gem "uglifier", ">= 1.0.3"
gem "unicorn"
gem "dotenv"
gem "dotenv-deployment"
gem "rollbar"

group :development do
  gem 'foreman'

  gem 'capistrano', require: false
  gem 'capistrano-rvm', require: false
  gem 'capistrano-resque', require: false
  gem 'capistrano-rails', require: false
end

group :development, :test do
  gem 'byebug'
  gem 'poltergeist'
  gem 'rspec-rails', '>= 2.14'
end

group :test do
  gem 'capybara', '~> 2.1.0'
  gem 'selenium-webdriver'
  gem 'database_cleaner'
  gem 'factory_girl_rails'
  gem 'launchy'
  gem 'shoulda-matchers'
  gem 'webmock'
end
