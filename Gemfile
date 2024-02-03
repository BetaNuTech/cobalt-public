source 'https://rubygems.org'

# specifies the ruby version to use for the app
ruby '3.1.4'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7.0'
# Use postgresql as the database for Active Record
gem 'pg'
# Use SCSS for stylesheets
gem 'sass-rails', '>= 6'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder'

# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', group: :doc

# The web server
gem 'puma'

# "There is no request timeout mechanism inside of Puma," so we need one
gem 'rack-timeout'

# Allows us to read Excel files
gem 'roo'
gem 'roo-xls'

# jquery UI
gem 'jquery-ui-rails', '~> 5.0', '>= 5.0.5'

# using the heroku gem b/c the toolbelt has issues detecting correct version of
# ruby when executing command lines on heroku from the deploy script

# Hosting platform
#gem 'heroku'

# For bug tracking
gem 'airbrake'

# Authentication
gem 'devise'

# So email invitations to users
gem 'devise_invitable'

# Authorization - see ability.rb
gem 'cancancan'

# Allows for UI multiselect box
gem 'multi-select-rails'

# Allows the user to add comments in UI on any model, used for BlueShifts
# sassc-rails & jquery-rails required as well
gem 'commontator'
gem 'sassc-rails'

# Used by heroku or foreman to schedule jobs
gem 'clockwork'

# Delayed Job for ActiveRecord - runs background jobs, where jobs are stored in the database
# TODO: There is a migration to do for this now
gem 'delayed_job_active_record'

# Allows you to run the application using the Procfile with web,work,and clock processes
gem 'foreman'

# jquery file upload, used by BlueShifts
gem 'jquery-fileupload-rails'

# Used with jquery file upload to direct upload to S3 and store the URL in the 
# form so it can be submitted
gem 's3_file_field'

# Delay Job admin console - go to http://www.rooturl.com/jobs
gem 'delayed-web'

# Added for DelayedJobs to work (after rails upgrade)
gem 'daemons'

# Automatically records audits on specified models and attributes and display in the UI
# TODO: Find a replacement
# gem 'audited-activerecord'
gem 'audited'

# Allows a SQL union between to Arel queries
gem 'active_record_union'

# Calculates a moving average for data which is used by the graphs
gem 'moving_average'

# Ruby client library fo Slack API
gem 'slack-ruby-client', '~> 2.1'

# View helper that we automatically create links for text that has URLs
gem "rails_autolink"

# Covert HTML to an image, for slack bots
gem 'imgkit'

# An XML toolkit for Ruby
gem 'rexml'

# HTTP/REST API client library, used by slack-ruby-client, to upload an image
gem 'faraday', '~> 2.7.4'
gem 'faraday-net_http'

# AWS SDK, used to S3 storage
gem 'aws-sdk'

# New Relic, for monitoring app
# TODO: Need to bring back or replace (Removed for Rails 6.1)
# gem 'newrelic_rpm'

# Makes http fun! Also, makes consuming restful web services dead easy.
gem 'httparty'

# Convert numbers to words
gem 'humanize'

gem 'annotate'

gem 'carrierwave'

# Resize images, using carrierwave
gem 'mini_magick'

# Store images in S3, using carrierwave
gem 'fog-aws'

# To work with Google Drive API / Sheet class
# gem 'google-drive', '~> 3'

# gem 'activesupport'

# Format to string the diff between to Times
gem 'dotiw'

# Added to fix bundle issues
gem 'bootsnap'

# Added for Rails 6.1
gem 'listen'

# Added for Rails 6.1
gem 'psych', '~> 3.0'

# Added for Rails 7.0
gem "sprockets-rails"

gem 'i18n', '~> 1.13.0'

group :production do
  # Needed by Heroku, implements some best practices for Rails 
  gem 'rails_12factor'
end

group :development, :test do
  # Debugger for rails, use binding.pry in the code to set a breakpoint
  gem 'pry'
  gem 'awesome_print'
  
  # Allows you to use a .env file to set your ENV variables on your local machine
  gem 'dotenv-rails'

  gem 'factory_bot_rails'
  gem 'faker'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  
  # Letter opener allows emails to automatically open in the web browsers instead of being sent
  gem 'letter_opener'
end

group :test do 
  # Nice test output
  # gem 'minitest-reporters', "~> 1.4"
  
  # Mocking framework
  gem 'mocha'

	gem 'database_cleaner-active_record'

	# gem 'rspec-rails'
  gem 'timecop'
	gem 'simplecov'
  gem 'shoulda-matchers'
  gem 'rails-controller-testing'
  gem 'warden-rspec-rails'
end

# This needs to initialized after the 'dotenv-rails' gem
# This provides the Setting class with setting.yml where you can configure global settings
gem "settingslogic"

