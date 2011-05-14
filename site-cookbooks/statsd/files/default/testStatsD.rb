#!/usr/bin/env ruby
require 'socket'

source = `hostname`.strip
target = ARGV[0] || 'localhost'
port = ARGV[1] || '8125'
interval = ARGV[2] || 5

s = UDPSocket.new

loop {
    s.send("testStatsRun.#{source}:1|c", 0, target, port)
    File.open("/proc/loadavg", "r") do |infile|
        averages = infile.gets.split(' ')
#         print "Sending #{averages.join(' ')} to #{target}:#{port}\n"
        s.send("load.#{source}.one:#{averages[0]}|ms", 0, target, port)
        s.send("load.#{source}.five:#{averages[1]}|ms", 0, target, port)
        s.send("load.#{source}.fifteen:#{averages[2]}|ms", 0, target, port)
    end
    sleep interval
}