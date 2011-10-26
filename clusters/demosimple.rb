ClusterChef::Cloud::Ec2::IMAGE_INFO.merge!({
    %w[us-east-1             64-bit  ebs             mrflip-natty       ] => { :image_id => 'ami-199b5470', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-cluster_chef", }, #
  })
# ami-a979b5c0

ClusterChef.cluster 'demosimple' do
  mounts_ephemeral_volumes

  cloud :ec2 do
    availability_zones  ['us-east-1a']
    flavor              "t1.micro"
    backing             "ebs"
    image_name          "mrflip-natty"
    bootstrap_distro    "ubuntu10.04-cluster_chef"
  end

  role                  :base_role
  role                  :chef_client
  role                  :ssh
  cluster_role

  #
  # An NFS server to hold your home drives.
  #
  # It's stop-start'able, but if you're going to use this long-term, you should
  # consider creating a separate EBS volume to hold /home
  #
  facet :homebase do
    instances           1
    role                :nfs_server
    facet_role
  end

  #
  # A throwaway facet for testing
  #
  facet :sandbox do
    instances           3
    role                :nfs_client
    cloud do
      flavor           "m1.large"
      backing          "ebs"
    end
  end


  #
  # A throwaway facet for AMI generation
  #
  facet :burninator do
    instances           2
    cloud do
      flavor           "m1.large"
      backing          "ebs"
    end

    role                :nfs_client
    recipe              'java::sun'
    recipe              'jpackage'
    role                :big_package
    role                :elasticsearch_client
    role                :hadoop
    recipe              'boost'
    recipe              'git'
    recipe              'mysql'
    recipe              'mysql::client'
    recipe              'ntp'
    recipe              'openssl'
    recipe              'thrift'
    recipe              'xfs'
    role                'https_server'

    facet_role do
      override_attributes({
          :hadoop => {
            :hadoop_handle        => 'hadoop-0.20',
            :cdh_version          => 'cdh3u1',
            :deb_version          => "0.20.2+923.97-1~maverick-cdh3",
            :cloudera_distro_name => 'maverick', # in case cloudera doesn't have your distro yet
          },
          :elasticsearch => {
            :version              => '0.17.8',
          },
          :service_states => {
            :hadoop_namenode           => [:enable],
            :hadoop_secondary_namenode => [:enable],
            :hadoop_jobtracker         => [:enable],
            :hadoop_datanode           => [:enable],
            :hadoop_tasktracker        => [:enable],
          },
          :active_users => [ "flip"],
          :authorization => { :sudo => { :groups => ['admin'], :users => ['ubuntu'] } },
          :groups => {
            'deploy'        => { :gid => 2000, },
            #
            'admin'         => { :gid =>  200, },
            'sudo'          => { :gid =>  201, },
            #
            'hadoop'        => { :gid =>  300, },
            'supergroup'    => { :gid =>  301, },
            'hdfs'          => { :gid =>  302, },
            'mapred'        => { :gid =>  303, },
            'hbase'         => { :gid =>  304, },
            'zookeeper'     => { :gid =>  305, },
            #
            'cassandra'     => { :gid =>  330, },
            'databases'     => { :gid =>  331, },
            'azkaban'       => { :gid =>  332, },
            'redis'         => { :gid =>  335, },
            'memcached'     => { :gid =>  337, },
            'jenkins'       => { :gid =>  360, },
            'elasticsearch' => { :gid =>  61021, },
            #
            'webservers'    => { :gid =>  401, },
            'nginx'         => { :gid =>  402, },
            'scraper'       => { :gid =>  421, },
          },
        })

    end
  end

end

# sudo service chef-client stop
# ps auxf
# df -BG
#
# away_dir=/tmp/ami_away
# sudo mkdir -p $away_dir
#
# # Tidy up the joint for the next occupants
# sudo apt-get -y update  ;
# sudo apt-get -y upgrade ;
# sudo apt-get -f install ;
# sudo apt-get clean ;
# sudo updatedb ;
#
# # move away anything tied to the identity of this machine
# sudo mv /etc/hostname /etc/node*name /var/www/index.html $away_dir
# # move away chef junk
# sudo mv /var/chef /etc/chef/{client-config.json,first-boot.json,node-attrs.json,chef-config.json,*.pem,*~} $away_dir
#
# # pull in a clean /etc/chef/client.rb
# sudo bash -c 'curl https://raw.github.com/gist/1294525/03e95f325b7c0790c27c890f7049b7b8dea07f96/etc-chef-client.rb > /etc/chef/client.rb'
# sudo chmod og-rwx /etc/chef/client.rb
#
# # zero out all files in /var/log
# cd /var/log ; for foo in `sudo find /var/log -type f` ; do echo $foo ; sudo bash -c "echo -n > $foo"  ; done
#
# # make a nice bland motd
# sudo rm /etc/motd ;
# sudo bash -c 'echo "CHIMP CHIMP CHIMP CRUNCH CRUNCH CRUNCH (image burned at `date`)" > /etc/motd ' ;
#
# # unmount your mountables
# for foo in /home /ebs* /data ; do sudo umount $foo ; done
#
# # Go to the console; hit 'stop' on the machine, count to 100, and then hit '
# # name the AMI something like
# # infochimps-natty-64bit-useast1-ruby19-dev-20111017
