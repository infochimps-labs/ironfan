require File.dirname(__FILE__)+'/../settings'

# Install with
#   knife role from file roles/base_role.rb

name 'base_role'
description 'top level attributes, applies to all nodes'

run_list *%w[
  sudo
  emacs
  git
  java
  users
  ]
  # users::env
  # users::homes
  # base_recipe

# Attributes applied if the node doesn't have it set already.
default_attributes({
    :groups => {
      'admin'      => { :gid => 116 },
      'sudo'       => { :gid => 27 },
      'supergroup' => { :gid => 1004 },
      'hadoop'     => { :gid => 113 },
    },
    :users => {
      'hadoop' => { :uid => 107, :gid => 113, }
      'flip' => { :gid => 1000, }
    },
    :active_users => %w[hadoop flip dhruv jacob carl ]

    :aws => {
      'aws_access_key'        => Settings[:access_key],
      'aws_secret_access_key' => Settings[:secret_access_key],
      'availability_zone'     => Settings[:availability_zones].first,
    },
    :authorization => { :sudo => { :groups => ['admin'], :users => ['flip'] } }
  })

# # Attributes applied no matter what the node has set already.
# override_attributes()

#
