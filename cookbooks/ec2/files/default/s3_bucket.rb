#!/usr/bin/env ruby
require 'rubygems'
require 'right_aws'
require 'thor'


class S3Bucket < Thor
  attr_reader :s3, :s3i
  
  desc "sync", "Sync a bucket to another bucket"
  method_options :source => :required, :target => :required,:aki => :required, :sak => :required

  def sync
    setup
    bucket = s3.bucket options[:source]
    backup_bucket = s3.bucket options[:target]
    keys = bucket.keys.collect {|b| b.name }
    backup_keys = backup_bucket.keys.collect {|b| b.name }
    keys_to_backup = keys - backup_keys

    if size = keys_to_backup.size > 0
      start = Time.now
      puts "Synchronizing #{size} keys from #{options[:source]} to #{options[:target]}"
      keys_to_backup.each {|k| puts "Copying key #{k}"; s3i.copy(options[:source], k, options[:target], k) }  
      total_time = Time.now - start
      puts "Finished in #{total_time / 60} minutes."
    else
      puts "Buckets are already in sync."
    end    
  end
  
  def setup
    @s3 = RightAws::S3.new(options[:aki],options[:sak])
    @s3i = RightAws::S3Interface.new(options[:aki],options[:sak])    
  end
end

S3Bucket.start