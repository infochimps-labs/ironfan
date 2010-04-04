require './settings.rb'
require 'right_aws'
RightAws::SdbInterface::API_VERSION = '2009-04-15'
require 'sdb/active_sdb'
require 'ohai'
OHAI_INFO = Ohai::System.new unless defined?(OHAI_INFO)
OHAI_INFO.all_plugins

#
# Make sure you are using a recent (>= 1.11,0) version of right_aws, and set the
# SDB_API_VERSION environment variable to '2009-04-15':
#   export SDB_API_VERSION='2009-04-15'
#

#
#
#
class Broham < RightAws::ActiveSdb::Base
  # Returns the last-registered host in the given role
  def self.host role
    select_by_role(role, :order => 'timestamp DESC')
  end

  # Returns all hosts in the given role
  def self.hosts role
    select_all_by_role(role, :order => 'timestamp DESC')
  end

  def self.register role, attrs={}
    ahost = host(role) || new
    ahost.attributes = ({:role => role, :timestamp => timestamp,
        :private_ip => my_private_ip, :public_ip => my_public_ip, :default_ip => my_default_ip,
        :fqdn => my_fqdn}.merge(attrs))
    success = ahost.save
    success ? self.new(success) : false
  end

  def yo!(*args)      register *args ; end
  def sup?(*args)      host *args    ; end
  def sup_bros?(*args) hosts *args   ; end


  #
  # Enlists as the next among many machines filling the given role.
  #
  # This is just a simple counter: it doesn't check whether the machine is
  # already enlisted under a different index, or whether there are missing
  # indices.
  #
  # It uses conditional save to be sure that the count is consistent
  #
  def self.register_as_next role, attrs={}
    my_idx = 0
    100.times do
      ahost = host(role) || new
      current_max_idx = ahost[:idx] && ahost[:idx].first
      my_idx          = (current_max_idx.to_i + 1)
      ahost.attributes = ({:role => role, :timestamp => timestamp, :idx => my_idx.to_s }.merge(attrs))
      expected = current_max_idx ? {:idx => (current_max_idx.to_i + rand(5)).to_s} : {}
      success = ahost.save_if(expected)
      break if success
    end
    register role+'-'+my_idx.to_s, { :idx => my_idx }.merge(attrs)
  end

  #
  # Removes all registrations for the given role
  #
  def self.unregister_all role
    select_all_by_role(role).each(&:delete)
  end

  #
  # Registration attributes
  #

  def self.my_private_ip()        OHAI_INFO[:cloud][:private_ips].first rescue nil ; end
  def self.my_public_ip()         OHAI_INFO[:cloud][:public_ips].first  rescue nil ; end
  def self.my_default_ip()        OHAI_INFO[:ipaddress]                            ; end
  def self.my_fqdn()              OHAI_INFO[:fqdn]                                 ; end
  def self.my_availability_zone() OHAI_INFO[:ec2][:availability_zone]              ; end
  def self.timestamp()            Time.now.utc.strftime("%Y%m%d%H%M%S")            ; end

  def private_ip()      self['private_ip'       ] ; end
  def public_ip()       self['public_ip'        ] ; end
  def default_ip()      self['default_ip'       ] ; end
  def fqdn()            self['fqdn'             ] ; end
  def availability_zone() self['availability_zone'] ; end
  def idx() self['idx']
  end

  def self.establish_connection
    @connection ||= RightAws::ActiveSdb.establish_connection(Settings[:access_key], Settings[:secret_access_key])
  end

  #
  #
  #

  # NFS: device path, for stuffing into /etc/fstab
  def self.nfs_device_path role='nfs_server'
    nfs_server = host(role) or return
    [nfs_server[:private_ip], nfs_server[:remote_path]].join(':')
  end

  # Hadoop: master jobtracker node
  def self.hadoop_jobtracker(role='hadoop_jobtracker') ; host(role) ; end
  # Hadoop: master namenode
  def self.hadoop_namenode(  role='hadoop_namenode')   ; host(role) ; end
  # Hadoop: cloudera desktop node
  def self.cloudera_desktop( role='cloudera_desktop')  ; host(role) ; end

  def to_hash() attributes ; end
end

Broham.establish_connection
Broham.create_domain
