source "http://rubygems.org"
ruby '1.9.3'

# Declare your gem's dependencies in artfully_ose.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

group :test, :development do
  gem 'sqlite3'
  gem 'rspec-rails', "~> 2.10.0"
  gem 'nokogiri'
  gem 'capybara'
  gem 'timecop'
  gem 'shoulda'
  gem 'fakeweb'
  gem 'faker'
  gem 'factory_girl', '~> 4.0'
  gem 'factory_girl_rails', '~> 4.0'
  gem 'mysql2'
  gem 'exceptional'
end

group :test do
  gem 'database_cleaner'
  gem 'spork-rails'
  gem "therubyracer", :require => 'v8'
  gem 'guard'
  gem 'guard-rspec'
  gem 'guard-spork'
  gem 'rb-fsevent', '~> 0.9'
  gem 'launchy'
  gem 'awesome_print', :require => 'ap'
  gem 'wirble'
  gem 'letter_opener'
  gem 'json_spec'
end

group :pg do
  gem 'pg'
end
