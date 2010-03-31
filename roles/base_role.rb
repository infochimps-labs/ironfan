# Install with
#   knife role from file roles/base_role.rb

name        'base_role'
description 'top level attributes, applies to all nodes'
require File.dirname(__FILE__)+'/../settings'

run_list *%w[
  sudo
  users
  git
  java
  emacs
  ]

# Attributes applied if the node doesn't have it set already.
default_attributes({
    :groups => {
      'admin'      => { :gid => 200 },
      'sudo'       => { :gid => 201 },
      'hadoop'     => { :gid => 300 },
      'supergroup' => { :gid => 301 },
      'dhruv'      => { :gid => 1001, },
      'jacob'      => { :gid => 1002, },
      'carl'       => { :gid => 1003, },
      'flip'       => { :gid => 1004, },
    },
    :users => {
      # passwords must be in shadow password format with a salt. To generate: openssl passwd -1
      'dhruv'  => { :uid => 1001, :groups => %w[dhruv  admin sudo supergroup], :password => '', :comment => "Dhruv Bansal", },
      'jacob'  => { :uid => 1002, :groups => %w[jacob  admin sudo supergroup], :password => '', :comment => "Jacob Perkins", },
      'carl'   => { :uid => 1003, :groups => %w[carl   admin sudo supergroup], :password => '', :comment => "Carl Knutson", },
      'flip'   => { :uid => 1004, :groups => %w[flip   admin sudo supergroup], :password => '', :comment => "Philip (flip) Kromer", },
    },
    :active_users => %w[flip dhruv jacob carl ],
    # :ssh_keys => {
    #   'hadoop' => '',
    # },

    :aws => {
      :aws_access_key        => Settings[:access_key],
      :aws_secret_access_key => Settings[:secret_access_key],
      :aws_endpoint_url      => Settings[:ec2_url],
      :availability_zone     => Settings[:availability_zones].first,
    },
    :authorization => { :sudo => { :groups => ['admin'], :users => ['flip'] } }
  })
