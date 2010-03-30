log_level                :info
log_location             STDOUT
node_name                'silverback'
client_key               '/Users/flip/.chef/silverback.pem'
validation_client_name   'chef-validator'
validation_key           '/Users/flip/.chef/chef-validator.pem'
chef_server_url          'http://chef.infinitemonkeys.info:4000'
cache_type               'BasicFile'
cache_options( :path => '/Users/flip/.chef/checksums' )
cookbook_path [ 'chef-repo/cookbooks', 'chef-repo/site-cookbooks', ].map{|path| File.join(ENV['HOME'], 'ics/sysadmin', path)}
