log_level                :info
log_location             STDOUT
node_name                'webui'
client_key               '/Users/flip/.chef/webui.pem'
validation_client_name   'validation'
validation_key           '/Users/flip/.chef/validation.pem'
chef_server_url          'http://chef.infinitemonkeys.info:4000'
cache_type               'BasicFile'
cache_options( :path => '/Users/flip/.chef/checksums' )
