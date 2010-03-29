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
  ]
  # users::env
  # users::homes
  # base_recipe

# Attributes applied if the node doesn't have it set already.
default_attributes({
    "base_role" => {
      'home_base_dir'         => '/home',
      'mnt_point'             => '/mnt',
      'bin_dir'               => '/usr/local/bin',
      'upstart_event_dir'     => '/etc/init',
      'target_user'           => 'ubuntu',
      'aws_access_key'        => Settings[:access_key],
      'aws_secret_access_key' => Settings[:secret_access_key],
      'availability_zone'     => Settings[:availability_zones].first,
      'sudoers_users'         => 'ubuntu flip',


    },
    :authorization => { :sudo => { :groups => ['admin'], :users => ['flip'] } }
  })

# # Attributes applied no matter what the node has set already.
# override_attributes()

#
