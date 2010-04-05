log_level                :info
log_location             STDOUT
node_name                'your_machine'
client_key               ENV['HOME']+'/.chef/your_machine.pem'
validation_client_name   'chef-validator'
validation_key           ENV['HOME']+'/.chef/chef-validator.pem'
chef_server_url          'http://chef.infinitemonkeys.info:4000'
cache_type               'BasicFile'
cookbook_path            [ 'hadoop_cluster_chef/cookbooks', 'hadoop_cluster_chef/site-cookbooks', ].map{|path| File.join(ENV['HOME'], 'ics/sysadmin', path)}
cache_options( :path => '/Users/flip/.chef/checksums' )
