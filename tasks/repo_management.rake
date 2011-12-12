# -*- ruby -*-

Bundler.setup(:default, :development, :support)

require 'rake/tasklib'
require 'fileutils'
require 'repoman'
require 'pry'

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

def get_repoman
  clxn = ClusterChef::Repoman::Collection.new(
    %w[ zookeeper bob ],
    :github_org  => GITHUB_ORG,
    :github_team => GITHUB_TEAM,
    )
  Log.dump(clxn)
  clxn
end

def get_repo(repo_name)
  repoman  = get_repoman
  repo     = repoman.repo(repo_name)
  Log.dump(repo)
  raise "Can't find repo #{repo_name}: only know about #{repoman.repo_names}" unless repo
  [repoman, repo]
end

def setup_repoman(rt, args)
  missing = rt.arg_names.select{|arg| args.send(arg).blank? }
  raise ArgumentError, "Please supply #{missing.join(', ')}: 'rake #{rt.name}#{rt.arg_description}'" unless missing.empty?
end


namespace :repo do

  namespace :bare do
    desc 'repo mgmt: Create given bare repo'
    task :create, [:repo_name] do |rt, args|
      setup_repoman(rt, args)
      repoman, repo = get_repo(args.repo_name)
      repo.invoke
    end
  end

  desc 'repo mgmt: Create all bare repos'
  task :bare do |rt, args|
    setup_repoman(rt, args)
    repoman = get_repoman
    cookbooks = FileList['meta-cookbooks/*'].select{|d| File.directory?(d) }
    cookbooks.each do |cookbook|
      cookbook_name = File.basename(cookbook)
      bare_task = ClusterChef::Repoman::Repo.new(repoman, cookbook_name)
      bare_task.invoke
    end
  end

  
  #
  # Manage the github repos
  #
  namespace :gh do
    desc 'repo mgmt: github target repo information'
    task :show, [:repo_name] do |rt, args|
      setup_repoman(rt, args)
      repoman, repo = get_repo(args.repo_name)
      info = repo.github_info
      puts JSON.pretty_generate(info)
    end

    desc 'repo mgmt: create github target repo'
    task :sync, [:repo_name] do |rt, args|
      setup_repoman(rt, args)
      repoman, repo = get_repo(args.repo_name)
      info = {}
      info[:create] = repo.github_create
      info[:auth  ] = repo.github_add_teams
      info[:update] = repo.github_update      
      # puts JSON.pretty_generate(info)
      Log.info("synced #{repo.name}")
    end
    
    desc 'repo mgmt: delete github target repo. must set the REPOMAN_LOOK_IN_TRUNK environment variable.'
    task :whack, [:repo_name] do |rt, args|
      setup_repoman(rt, args)
      repoman, repo = get_repo(args.repo_name)
      info = repo.github_delete!
      Log.info("whacked #{repo.name}")
    end    
  end
end

# container=$HOME/ics/schism
#
# # origin=infochimps/cluster_chef
# # gh_url="git@github.com:$origin"
# # starting_branch=version_3
#
# origin=infochimps-labs/opscode_cookbooks
# gh_url="git@github.com:$origin"
# starting_branch=master
# cookbooks="ant  apache2  apt  aws  boost  build-essential  cron" # database  git  iptables  java  jpackage  mysql  ntp  openssl  python  rsyslog  runit  rvm  thrift  ubuntu  ufw  xfs  xml  zabbix  zlib"
#
# gh_user=`git config --get github.user`
# gh_pass=`git config --get github.token`
# gh_org=infochimps-cookbooks
# gh_api="https://github.com/api/v2/json"
#
# # extra_subtree_args=' --annotate="s: "  --rejoin'

#
# # ===========================================================================
# #
# # Get Git
# #
#
# source=$container/$origin
# target=$container/target
# result=$container/result
# mkdir -p $container $target $result
#
# if [ -d $source ] ; then
#   echo "Using existing checkout of $gh_url in $source"
# else
#   mkdir -p `dirname $source`
#   cd       `dirname $source`
#   git clone $gh_url
#   cd $source
#   git checkout $starting_branch
#   git checkout -b version_3_schism || git checkout version_3_schism
# fi
#
# # ===========================================================================
# #
# # Git Splitty
# #
#
# cd $source
# for foo in $cookbooks ; do
#   repo=`basename $foo`
#
#   echo
#   echo -e "================================="
#   echo -e "==\n== Processing $repo\n==\n"
#
#   # # this is how I can just kill a repo. kablau.
#   # tok=$(curl -X POST -F "login=$gh_user" -F "token=$gh_pass" "$gh_api/repos/delete/$gh_org/$repo" | ruby -ne '$_ =~ /:"(.*)"/; puts $1') ; echo $tok ; curl -X POST -F "login=$gh_user" -F "token=$gh_pass"  -F "delete_token=$tok" "$gh_api/repos/delete/$gh_org/$repo"
#
#   echo -e "\n==\n== creating bare repo $target/$repo.git\n==\n"
#   mkdir -p $target/$repo.git
#   cd       $target/$repo.git
#   if   [ -f $target/$repo.git/HEAD ] ;
#   then echo "repo exists, not initializing" ;
#   else git init --bare
#   fi
#
#   echo -e "\n==\n== splitting git history into $repo branch in $source\n==\n"
#   cd $source
#   git-subtree split -P $foo -b $repo $extra_subtree_args
#
#   echo -e "\n==\n== pushing into $target/$repo.git\n==\n"
#   git push $target/$repo.git $repo:master
#
#   echo -e "\n==\n== checking out new repo into $result/$repo\n==\n"
#   cd $result
#   git clone $target/$repo.git || true
#
#   echo -e "\n==\n== Pushing to git@github.com:$gh_org/$repo\n==\n"
#   cd $result/$repo
#   git remote add "$gh_org" "git@github.com:$gh_org/$repo" || true
#   git push --force -u "$gh_org"
#
# done
#
# echo
# echo "Done!"
