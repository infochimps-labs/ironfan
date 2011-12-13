# -*- ruby -*-

Bundler.setup(:default, :development, :support)

require 'rake/tasklib'
require 'fileutils'
require 'repoman'
require 'pry'

#
#
# * bare    a bare git repo, in /tmp/repoman/bare/foo.git
# * solo    a full git checkout, in /tmp/repoman/solo/foo
# * github
# * main holds two kinds of branches:
#   - mainline
#   - per-component branch for that component's subtree.

# Bibliography:
#
# Rake
# * https://sites.google.com/site/spontaneousderivation/rake-quick-reference
# * http://rubydoc.info/stdlib/rake/frames
# Github API
# * http://develop.github.com/p/repo.html

REPOMAN_ROOT_DIR = '/tmp/repoman'
GITHUB_ORG       = 'infochimps-cookbooks'
GITHUB_TEAM      = '117089'

#
# Gee this part here could serve to be a bit cleaner.
# yes, I am in fact commenting the various collections in and out and re-running.
#

# def get_repoman
#   cookbooks = FileList['site-cookbooks/*', 'meta-cookbooks/*'].select{|d| File.directory?(d) }.sort_by{|d| File.basename(d) }.reverse
#   #  cookbooks = cookbooks[18..-1] # .select{|c| c.to_s =~ /hadoop|cassandra/ }
#   clxn = ClusterChef::Repoman::Collection.new(
#     cookbooks,
#     :vendor   => 'infochimps',
#     :main_dir  => '/tmp/cluster_chef',
#     :github_org  => GITHUB_ORG,
#     :github_team => GITHUB_TEAM,
#     )
#   clxn
# end

# def get_repoman
#   cookbooks = %w[
#     ant apache2 apt aws bluepill boost build-essential chef-client chef-server
#     couchdb cron daemontools database emacs erlang gecode git iptables java
#     jpackage mysql nginx ntp openssh openssl python rabbitmq rsyslog runit
#     thrift ubuntu ucspi-tcp ufw xfs xml yum zlib zsh
#  ].reverse
#   # cookbooks = cookbooks[-6..-1]
#   clxn = ClusterChef::Repoman::Collection.new(
#     cookbooks,
#     :vendor   => 'opscode',
#     :main_dir  => '/tmp/opscode',
#     :github_org  => GITHUB_ORG,
#     :github_team => GITHUB_TEAM,
#     )
#   clxn
# end

# def get_repoman
#   ClusterChef::Repoman::Collection.new(['zabbix'],  :vendor => 'laradji', :main_dir => nil, :github_org  => GITHUB_ORG, :github_team => GITHUB_TEAM )
# end

# def get_repoman
#   ClusterChef::Repoman::Collection.new(['rvm'],     :vendor => 'fnichol', :main_dir => nil, :github_org  => GITHUB_ORG, :github_team => GITHUB_TEAM )
# end

def get_repo(repo_name)
  repoman  = get_repoman
  repo     = repoman.repo(repo_name)
  raise "Can't find repo #{repo_name}: only know about #{repoman.repo_names}" unless repo
  [repoman, repo]
end

def check_args(rt, args)
  missing = rt.arg_names.select{|arg| args.send(arg).blank? }
  raise ArgumentError, "Please supply #{missing.join(', ')}: 'rake #{rt.name}#{rt.arg_description}'" unless missing.empty?
end

def banner(rt, args, repo)
  puts "\n== #{"%-15s" % rt.name}\trepo #{"%-15s" % repo.name}\tpath #{repo.path}\n"
end


namespace :repo do

  desc 'repo mgmt: ensure all github targets exist'
  task :add_subtree_hack do |rt, args|
    check_args(rt, args)
    repoman = get_repoman
    repoman.subtree_add_all
  end

  desc 'repo mgmt: ensure all github targets exist'
  task :gh do |rt, args|
    check_args(rt, args)
    repoman = get_repoman
    repoman.each_repo do |repo|
      banner(rt, args, repo)
      repo.github_create
    end
  end

  desc 'repo mgmt: extract subtree split'
  task :subtree => [:gh] do |rt, args|
    check_args(rt, args)
    repoman = get_repoman
    repoman.in_main_tree do
      repoman.each_repo do |repo|
        banner(rt, args, repo)
        repo.git_subtree_split
      end
    end
  end

  desc 'repo mgmt: sync solo with tree'
  task :solo => [:gh] do |rt, args|
    check_args(rt, args)
    repoman = get_repoman
    repoman.each_repo do |repo|
      banner(rt, args, repo)
      repo.create_solo.invoke
    end
  end

  task :push => [:gh, :solo, :subtree ] do |rt, args|
    check_args(rt, args)
    repoman = get_repoman
    repoman.in_main_tree do
      repoman.each_repo do |repo|
        banner(rt, args, repo)
        repo.pull_to_solo_from_main.invoke
        repo.push_from_solo_to_github.invoke
      end
    end
  end

  #
  # Manage the github repos
  #
  namespace :gh do
    desc 'repo mgmt: github target repo information'
    task :show, [:repo_name] do |rt, args|
      check_args(rt, args)
      repoman, repo = get_repo(args.repo_name)
      info = repo.github_info
      puts JSON.pretty_generate(info)
    end

    desc 'repo mgmt: create github target repo'
    task :sync, [:repo_name] do |rt, args|
      check_args(rt, args)
      repoman, repo = get_repo(args.repo_name)
      repo.github_sync
    end

    desc 'repo mgmt: ensure all github targets exist'
    task :sync_all do |rt, args|
      check_args(rt, args)
      repoman = get_repoman
      repoman.each_repo do |repo|
        banner(rt, args, repo)
        repo.github_sync
      end
    end

    desc 'repo mgmt: delete github target repo. must set the REPOMAN_LOOK_IN_TRUNK environment variable.'
    task :whack, [:repo_name] do |rt, args|
      check_args(rt, args)
      repoman, repo = get_repo(args.repo_name)
      info = repo.github_delete!
      Log.info("whacked #{repo.name}")
    end
  end

end
