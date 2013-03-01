source "http://rubygems.org"

gem 'chef',          "~> 10.16"
gem 'fog',           "~> 1.2"
gem 'formatador',    "~> 0.2"
gem 'gorillib',      "~> 0.4.2"

# Everything in the world is being a stupid dick about JSON versions. Pin it 
#   to the one that doesn't seem to angrify everyone.
gem 'json',          "= 1.5.4"

group :development do
  gem 'bundler',     "~> 1.0"
  gem 'rake'
  gem 'rspec',       "~> 2.8"
  gem 'yard',        ">= 0.7"
  #
  gem 'redcarpet',   ">= 2.1"
  gem 'oj',          ">= 1.2"
end

group :support do
  gem 'jeweler',     ">= 1.6"
  gem 'pry'
end

group :test do
  gem 'simplecov',   ">= 0.5",   :platform => :ruby_19
  #
  gem 'guard',       "~> 1"
  gem 'guard-rspec'
  gem 'guard-yard'
  gem 'ruby_gntp'
  gem 'ruby-debug19'
end
