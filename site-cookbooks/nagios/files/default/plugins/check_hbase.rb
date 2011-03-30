#!/usr/bin/env ruby
#
# Nagios check for HBase cluster health
# Copyright Infochimps, 2011
# Author: Chris Howe (howech@infochimps.com)


EXIT_OK = 0
EXIT_WARNING = 1
EXIT_CRITICAL = 2
EXIT_UNKNOWN = 3

f = File.popen("echo status | hbase shell")
result = f.readlines.select{|line| line =~ /\d+ servers, \d+ dead, \d+(\.\d+)? average load/}

if result.nil?
  puts "Error checking for HBase status"
  exit(EXIT_CRITICAL)
end


if( result[0] =~ /, (\d+) dead,/ && $1.to_i > 0 )
  puts "HBase reports #{$1} dead servers: #{result[0]}"
  exit(EXIT_CRITICAL)
end

puts "HBase OK: #{result[0]}"

