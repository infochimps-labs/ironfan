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
  build-essential
  xml
  zlib
  ]

# Attributes applied if the node doesn't have it set already.
default_attributes({
    :aws => {
      :aws_access_key        => Settings[:access_key],
      :aws_secret_access_key => Settings[:secret_access_key],
      :aws_region            => Settings[:aws_region],
      :availability_zone     => Settings[:availability_zones].first,
    }
  })
