# frozen_string_literal: true

source 'https://rubygems.org'

ruby '3.1.4'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem 'rails', '~> 7.1.5', '>= 7.1.5.2'

# Use postgresql as the database for Active Record
gem 'pg', '~> 1.1'

# Use the Puma web server [https://github.com/puma/puma]
gem 'dotenv-rails', '~> 2'
gem 'puma', '>= 5.0'

# API
gem 'active_model_serializers', '~> 0.10.12'
gem 'kaminari', '~> 1.2'
gem 'rack-cors'

# Use Redis adapter to run Action Cable in production
gem 'redis'
gem 'redis-rails'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[windows jruby]

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[mri windows]
  gem 'factory_bot_rails'
  gem 'pry'
  gem 'rspec-rails'
  gem 'rubocop', require: false
  gem 'rubocop-factory_bot', require: false
  gem 'rubocop-graphql', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rake', require: false
  gem 'rubocop-rspec', require: false

  # Parsing .... T_T
  gem 'food_ingredient_parser'
  gem 'ingreedy', '~> 0.1.0'
end

group :development do
  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem 'spring'

  gem 'error_highlight', '>= 0.4.0', platforms: [:ruby]

  gem 'annotate'

  # Can be usefull to play with Jaeger locally
  # gem 'opentelemetry-exporter-otlp'
  # gem 'opentelemetry-instrumentation-all'
  # gem 'opentelemetry-sdk'
end
