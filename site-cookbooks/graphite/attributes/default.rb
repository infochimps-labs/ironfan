
default[:graphite][:conf_dir]                            = '/etc/graphite/'
default[:graphite][:data_dir]                            = nil
default[:graphite][:home_dir]                            = '/usr/local/share/graphite/'
default[:graphite][:log_dir]                             = '/var/log/graphite'


default[:graphite][:user]                                = 'graphite'
default[:graphite][:graphite_web][:user]                 = 'www-data'

default[:users ]['graphite'][:uid] = 446
default[:groups]['graphite'][:gid] = 446

default[:graphite][:carbon      ][:line_rcvr_addr]       = "127.0.0.1"
default[:graphite][:carbon      ][:pickle_rcvr_addr]     = "127.0.0.1"
default[:graphite][:carbon      ][:cache_query_addr]     = "127.0.0.1"

default[:graphite][:carbon      ][:version]              = "0.9.7"
default[:graphite][:carbon      ][:release_url]          = "http://launchpadlibrarian.net/61904798/carbon-0.9.7.tar.gz"
default[:graphite][:carbon      ][:release_url_checksum] = "ba698aca"

default[:graphite][:whisper     ][:version]              = "0.9.7"
default[:graphite][:whisper     ][:release_url]          = "http://launchpadlibrarian.net/61904764/whisper-0.9.7.tar.gz"
default[:graphite][:whisper     ][:release_url_checksum] = "c6272ad6"

default[:graphite][:graphite_web][:version]              = "0.9.7c"
default[:graphite][:graphite_web][:release_url]          = "http://launchpadlibrarian.net/62379635/graphite-web-0.9.7c.tar.gz"
default[:graphite][:graphite_web][:release_url_checksum] = "a3e16265"
