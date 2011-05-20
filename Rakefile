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
TOPDIR = File.expand_path(File.join(File.dirname(__FILE__), "."))

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name        = "cluster_chef"
  gem.homepage    = "http://infochimps.com/labs"
  gem.license     = "MIT"
  gem.summary     = %Q{Chef is a powerful tool for maintaining and describing the software and configurations that let a machine provide its services.}
  gem.description = %Q{Chef is a powerful tool for maintaining and describing the software and configurations that let a machine provide its services.}
  gem.email       = "coders@infochimps.org"
  gem.authors     = ["Infochimps"]

  gem.add_development_dependency 'bundler', "~> 1.0.12"
  gem.add_development_dependency 'jeweler', "~> 1.5.2"

  ignores = File.readlines(".gitignore").grep(/^[^#]\S+/).map{|s| s.chomp }
  dotfiles = [".gemtest", ".gitignore", ".rspec", ".yardopts"]
  gem.files = dotfiles + Dir["**/*"].
    reject{|f| f =~ %r{^(clusters|config|cookbooks|data_bags|roles|site-cookbooks)/} }.
    reject{|f| File.directory?(f) }.
    reject{|f| ignores.any?{|i| File.fnmatch(i, f) || File.fnmatch(i+'/**/*', f) } }
  gem.test_files = gem.files.grep(/^spec\//)
  gem.require_paths = ['lib']
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
  spec.rcov_opts = %w[ --exclude .rvm --no-comments --text-summary]
end

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new

TEST_CACHE = File.expand_path(File.join(TOPDIR, ".rake_test_cache"))
COMPANY_NAME = "Opscode, Inc."
SSL_EMAIL_ADDRESS = "cookbooks@opscode.com"
NEW_COOKBOOK_LICENSE = :apachev2

#
# load all rake tasks in ./tasks/*.rake
#
Dir[ File.join(File.dirname(__FILE__), 'tasks', '*.rake') ].sort.each do |f|
  load f
end

load 'chef/tasks/chef_repo.rake'
task :default => [ :test ]

desc "Build a bootstrap.tar.gz"
task :build_bootstrap do
  bootstrap_files = Rake::FileList.new
  %w(apache2 runit couchdb stompserver chef passenger ruby packages).each do |cookbook|
    bootstrap_files.include "#{cookbook}/**/*"
  end

  tmp_dir = "tmp"
  cookbooks_dir = File.join(tmp_dir, "cookbooks")
  rm_rf tmp_dir
  mkdir_p cookbooks_dir
  bootstrap_files.each do |fn|
    f = File.join(cookbooks_dir, fn)
    fdir = File.dirname(f)
    mkdir_p(fdir) if !File.exist?(fdir)
    if File.directory?(fn)
      mkdir_p(f)
    else
      rm_f f
      safe_ln(fn, f)
    end
  end

  chdir(tmp_dir) do
    sh %{tar zcvf bootstrap.tar.gz cookbooks}
  end
end

# remove unnecessary tasks
%w{update install roles ssl_cert}.each do |t|
  Rake.application.instance_variable_get('@tasks').delete(t.to_s)
end
