#
# Burninator cluster -- populate an AMI with installed software, but no
# services, users or other preconceptions.
#
# The script /tmp/burn_ami_prep.sh will help finalize the machine -- then, just
# stop it and invoke 'Create Image (EBS AMI)'.
#

ClusterChef.cluster 'burninator' do
  cloud(:ec2) do
    defaults
    availability_zones ['us-east-1d']
    flavor              'c1.xlarge'
    backing             'ebs'
    image_name          'natty'
    bootstrap_distro    'ubuntu10.04-cluster_chef'
    chef_client_script  'client.rb'
    mount_ephemerals(:tags => { :hadoop_scratch => true })
  end

  role                  :base_role
  role                  :chef_client
  role                  :ssh

  environment           :dev

  #
  # A throwaway facet for AMI generation
  #
  facet :sandbox do
    instances           1

    recipe              'cluster_chef::burn_ami_prep'

    role                'big_package'
    role                'elasticsearch_client'
    role                'hadoop'
    role                'pig'
    role                'web_server'

    recipe              'boost'
    recipe              'build-essential'
    recipe              'git'
    recipe              'java::sun'
    recipe              'jpackage'
    recipe              'jruby'
    recipe              'nodejs'
    recipe              'ntp'
    recipe              'openssl'
    recipe              'runit'
    recipe              'thrift'
    recipe              'xfs'
    recipe              'xml'
    recipe              'zlib'
  end

  facet :testy do
    instances        1
    cloud.image_name 'infochimps-natty'
  end

  cluster_role.override_attributes({
      :apt => { :cloudera => {
          :force_distro => 'maverick', # no natty distro  yet
          :release_name => 'cdh3u2',
        }, },
      :mountable_volumes => {
        :aws_credential_source => 'node_attributes',
      },
      :hadoop => {
        :hadoop_handle        => 'hadoop-0.20',
        :deb_version          => '0.20.2+923.142-1~maverick-cdh3',
      },
    })

end
