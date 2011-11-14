#
# Rakefile for Chef Server Repository
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
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'chef'
require 'json'
require 'jeweler'
require 'rspec/core'
require 'rspec/core/rake_task'
require 'yard'

# Load constants from rake config file.
require File.join(File.dirname(__FILE__), 'config', 'rake')

# ---------------------------------------------------------------------------
#
# Chef tasks
#
# Load common, useful tasks from Chef.
# rake -T to see the tasks this loads.
#

# # Detect the version control system and assign to $vcs. Used by the update
# # task in chef_repo.rake (below). The install task calls update, so this
# # is run whenever the repo is installed.
# #
# # Comment out these lines to skip the update.
# if File.directory?(File.join(TOPDIR, ".svn"))
#   $vcs = :svn
# elsif File.directory?(File.join(TOPDIR, ".git"))
#   $vcs = :git
# end

load 'chef/tasks/chef_repo.rake'

desc "Bundle a single cookbook for distribution"
task :bundle_cookbook => [ :metadata ]
task :bundle_cookbook, :cookbook do |t, args|
  tarball_name      = "#{args.cookbook}.tar.gz"
  temp_dir          = File.join(Dir.tmpdir, "chef-upload-cookbooks")
  temp_cookbook_dir = File.join(temp_dir, args.cookbook)
  tarball_dir       = File.join(TOPDIR, "pkgs")
  FileUtils.mkdir_p(tarball_dir)
  FileUtils.mkdir(temp_dir)
  FileUtils.mkdir(temp_cookbook_dir)

  child_folders = [ "cookbooks/#{args.cookbook}", "site-cookbooks/#{args.cookbook}" ]
  child_folders.each do |folder|
    file_path = File.join(TOPDIR, folder, ".")
    FileUtils.cp_r(file_path, temp_cookbook_dir) if File.directory?(file_path)
  end

  system("tar", "-C", temp_dir, "-cvzf", File.join(tarball_dir, tarball_name), "./#{args.cookbook}")

  FileUtils.rm_rf temp_dir
end

# ---------------------------------------------------------------------------
#
# Jeweler -- release cluster_chef as a gem
#
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name        = "cluster_chef"
  gem.homepage    = "http://infochimps.com/labs"
  gem.license     = NEW_COOKBOOK_LICENSE.to_s
  gem.summary     = %Q{cluster_chef allows you to orchestrate not just systems but clusters of machines. It includes a powerful layer on top of knife and a collection of cloud cookbooks.}
  gem.description = %Q{cluster_chef allows you to orchestrate not just systems but clusters of machines. It includes a powerful layer on top of knife and a collection of cloud cookbooks.}
  gem.email       = SSL_EMAIL_ADDRESS
  gem.authors     = ["Infochimps"]

  gem.add_development_dependency 'bundler', "~> 1.0.12"
  gem.add_development_dependency 'jeweler', "~> 1.5.2"

  ignores = File.readlines(".gitignore").grep(/^[^#]\S+/).map{|s| s.chomp }
  dotfiles = [".gemtest", ".gitignore", ".rspec", ".yardopts"]
  gem.files = dotfiles + Dir["**/*"].
    reject{|f| f =~ %r{^(cookbooks|site-cookbooks|meta-cookbooks|integration-cookbooks)} }.
    reject{|f| f =~ %r{^(certificates|clusters|config|data_bags|environments|roles|chefignore|deprecated|tasks)/} }.
    reject{|f| File.directory?(f) }.
    reject{|f| ignores.any?{|i| File.fnmatch(i, f) || File.fnmatch(i+'/**/*', f) } }
  gem.test_files = gem.files.grep(/^spec\//)
  gem.require_paths = ['lib']
end
Jeweler::RubygemsDotOrgTasks.new

# ---------------------------------------------------------------------------
#
# RSpec -- testing
#
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
  spec.rcov_opts = %w[ --exclude .rvm --no-comments --text-summary]
end

# ---------------------------------------------------------------------------
#
# Yard -- documentation
#
YARD::Rake::YardocTask.new

# ---------------------------------------------------------------------------

task :default => :spec
