#!/usr/bin/env bash

set -v
set -e

main=/tmp/repoman/main
solo=/tmp/repoman/solo/cassandra
repo_path=site-cookbooks/cassandra
repo=`basename $repo_path`

#
# One time: get the repo, break all ties with world
#
cd /tmp
rm -rf /tmp/cluster_chef
git clone git@github.com:infochimps-labs/cluster_chef.git
cd /tmp/cluster_chef
git checkout -b version_3_cookbooks_restored origin/version_3_cookbooks_restored
git checkout -b main
git branch   -d version_3_cookbooks_restored
git branch   -d master
git remote rm origin

#
# pull subtree
#
cd /tmp/cluster_chef
git subtree split -P $repo_path -b br-$repo --annotate 's: ' --rejoin

# #
# # make solo repo
# #
# if [ ! -e $solo ] ; then
#   mkdir -p `dirname $solo`
#   cd       `dirname $solo`
#   git clone git@github.com:infochimps-cookbooks/$repo.git
#   cd       $solo
#   git pull /tmp/cluster_chef/.git br-$repo:master
# fi
# 
# #
# # main repo
# #
# if [ ! -e $main ] ; then
#   mkdir $main ; cd $main ; git init  ; echo "empty test repo" > "foogit.txt"
#   git add . ; git commit -m "initial commit to empty repo" .
#   git checkout -b main
#   git branch   -D master
# fi    
# 
# #
# # pull subtree into main
# #
# cd $main
# git subtree add   -P $repo_path /tmp/repoman/solo/$repo/.git master
# git subtree split -P $repo_path -b br-$repo --annotate 's: ' --rejoin

# echo -e "\n\nYou should see $repo, hadoop_cookbooks, etc etc\n\n"
# git checkout br-site-cookbooks
# ls
# echo -e "\n\nYou should see site-cookbooks, foogit.txt etc\n\n"
# git checkout main
# ls
# echo -e "\n\nYou should see branches for main and br-site-cookbooks, and be on main\n\n"
# git branch -a
# 
# # cd $solo
# # step="testing step 1: changed in solo" ; file=testing_step.txt;  echo "file says: $step" > $file ; git add $file ; git commit -m "$step"
# 
# # cd $main
# # git subtree pull -P site-cookbooks $solo/.git master
# 
# cd $main
# step="testing step 2: changed in main" ; file=site-cookbooks/testing_step.txt;  echo "file says: $step" > $file ; git add $file ; git commit -m "$step"  || true
# git subtree split -P site-cookbooks -b br-site-cookbooks
# 
# cd $solo
# git pull /tmp/repoman/main/.git br-site-cookbooks:master
# cat testing_step.txt
# 
# cd $main
# step="testing step 3: changed in main" ; file=site-cookbooks/testing_step.txt;  echo "file says: $step" > $file ; git add $file ; git commit -m "$step" || true
# git subtree split -P site-cookbooks -b br-site-cookbooks
# 
# cd $solo
# git pull /tmp/repoman/main/.git br-site-cookbooks:master || true
# cat testing_step.txt
# 
# cd $main
# git subtree pull -P site-cookbooks $solo/.git master
# git subtree split -P site-cookbooks -b br-site-cookbooks

