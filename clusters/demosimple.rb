ClusterChef.cluster 'demosimple' do
  cloud(:ec2) do
    defaults
    availability_zones ['us-east-1d']
    image_name          'natty'
  end

  role                  :base_role
  role                  :chef_client
  role                  :ssh
  role                  :mountable_volumes

  #
  # An NFS server to hold your home drives.
  #
  # It's stop-start'able, but if you're going to use this long-term, you should
  # consider creating a separate EBS volume to hold /home
  #
  facet :homebase do
    instances           1
    role                :nfs_server

    # #
    # # Follow the directions in the aws cookbook about an AWS credentials databag
    # #
    # volume(:home) do
    #   defaults
    #   size                15
    #   device              '/dev/sdh'       # note: will appear as /dev/xvdi on natty
    #   mount_point         '/home'
    #   attachable          :ebs
    #   # snapshot_id       ''               # create a snapshot and place its id here
    #   create_at_launch    true             # if no volume is tagged for that node, it will be created
    #   tags                :home => '/home'
    # end
  end

  #
  # A throwaway facet for development.
  #
  facet :sandbox do
    instances           2
    role                :nfs_client
  end

end
