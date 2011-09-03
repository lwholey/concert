source 'http://rubygems.org'

gem 'rails', '3.0.9'
gem 'will_paginate', '3.0.pre2'
gem 'sqlite3', '1.3.3'
gem 'eventfulapi'

group :development do
  gem 'rspec-rails', '2.6.1'
  gem 'annotate', '2.4.0'
  gem 'faker', '0.3.1'
end

# Followed instructions here:
# http://automate-everything.com/2009/08/gnome-and-autospec-notifications/
group :test do
  gem 'rspec-rails', '2.6.1'
  gem 'webrat', '0.7.1'
  gem 'spork', '0.9.0.rc8'
  gem 'factory_girl_rails', '1.0'
  gem 'autotest', '4.4.6'
  gem 'autotest-rails-pure', '4.1.2'
  gem 'ZenTest' if RUBY_PLATFORM =~ /linux/
  gem 'redgreen' if RUBY_PLATFORM =~ /linux/
  gem 'test-unit' if RUBY_PLATFORM =~ /linux/
  gem 'autotest-fsevent', '0.2.4' if RUBY_PLATFORM =~ /darwin/
  gem 'autotest-growl', '0.2.9' if RUBY_PLATFORM =~ /darwin/
end
