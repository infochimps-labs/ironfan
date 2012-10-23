#
# Rakefile for Cluster Chef Knife plugins
#
# Author::    Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
# License::   Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'rubygems' unless defined?(Gem)
require 'bundler'
begin
  Bundler.setup(:default, :development, :support)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'json'
require 'jeweler'
require 'rspec/core/rake_task'
require 'yard'

# Load constants from rake config file.
$LOAD_PATH.unshift('tasks')
Dir[File.join('tasks', '*.rake')].sort.each{|f| load(f) }

# ---------------------------------------------------------------------------
#
# Jeweler -- release ironfan as a gem
#

Jeweler::Tasks.new do |gem|
  gem.name        = 'ironfan'
  gem.homepage    = "http://infochimps.com/labs"
  gem.license     = NEW_COOKBOOK_LICENSE.to_s
  gem.summary     = %Q{Ironfan allows you to orchestrate not just systems but clusters of machines. It includes a powerful layer on top of knife and a collection of cloud cookbooks.}
  gem.description = %Q{Ironfan allows you to orchestrate not just systems but clusters of machines. It includes a powerful layer on top of knife and a collection of cloud cookbooks.}
  gem.email       = SSL_EMAIL_ADDRESS
  gem.authors     = ["Infochimps"]

  ignores = File.readlines(".gitignore").grep(/^[^#]\S+/).map{|s| s.chomp }
  dotfiles = [".gemtest", ".gitignore", ".rspec", ".yardopts"]
  gem.files = dotfiles + Dir["**/*"].
    reject{|f| File.directory?(f) }.
    reject{|f| ignores.any?{|i| File.fnmatch(i, f) || File.fnmatch(i+'/*', f) || File.fnmatch(i+'/**/*', f) } }
  gem.test_files = gem.files.grep(/^spec\//)
  gem.require_paths = ['lib']
end
Jeweler::RubygemsDotOrgTasks.new

# ---------------------------------------------------------------------------
#
# RSpec -- testing
#
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/{ironfan,chef,ironfan/*}/*_spec.rb'
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
  spec.rcov_opts = %w[ --exclude .rvm --no-comments --text-summary ]
end

RSpec::Core::RakeTask.new(:integration) do |spec|
  spec.pattern = 'spec/integration/**/*_spec.rb'
end

# ---------------------------------------------------------------------------
#
# Yard -- documentation
#
YARD::Rake::YardocTask.new
desc "Alias for 'rake yard'"
task :doc => :yard

# ---------------------------------------------------------------------------

task :default => :spec
