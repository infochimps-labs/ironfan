require 'digest/md5'

module Ironfan
  class Dsl

    class Compute < Ironfan::Dsl
      def ec2(*attrs,&block)            cloud(:ec2,*attrs,&block);      end

      def elastic_ip(address)
        pp(self.fog_connection)
        pp(self.fog_server)
        Ironfan.safely do
          Ironfan.fog_connection.associate_address(self.fog_server.id, address)
        end
      end
    end

    class Ec2 < Cloud
      magic :availability_zones,        Array,          :default => ['us-east-1d']
      magic :backing,                   String,         :default => 'ebs'
      magic :bits,                      Integer,        :default => ->{ flavor_info[:bits] }
      magic :bootstrap_distro,          String,         :default => ->{ image_info[:bootstrap_distro] }
      magic :chef_client_script,        String
      magic :default_availability_zone, String,         :default => ->{ availability_zones.first }
      magic :elastic_ip,                String
      collection :elastic_load_balancers,  Ironfan::Dsl::Ec2::ElasticLoadBalancer, :key_method => :name
      magic :flavor,                    String,         :default => 't1.micro'
      collection :iam_server_certificates, Ironfan::Dsl::Ec2::IamServerCertificate, :key_method => :name
      magic :image_id,                  String
      magic :image_name,                String
      magic :keypair,                   String
      magic :monitoring,                String
      magic :mount_ephemerals,          Hash,           :default => {}
      magic :permanent,                 :boolean,       :default => false
      magic :placement_group,           String
      magic :provider,                  Whatever,       :default => Ironfan::Provider::Ec2
      magic :public_ip,                 String
      magic :region,                    String,         :default => ->{ default_region }
      collection :security_groups,      Ironfan::Dsl::Ec2::SecurityGroup, :key_method => :name
      magic :ssh_user,                  String,         :default => ->{ image_info[:ssh_user] }
      magic :ssh_identity_dir,          String,         :default => ->{ Chef::Config.ec2_key_dir }
      magic :subnet,                    String
      magic :validation_key,            String,         :default => ->{ IO.read(Chef::Config.validation_key) rescue '' }
      magic :vpc,                       String

      def image_info
        bit_str = "#{self.bits.to_i}-bit" # correct for legacy image info.
        keys = [region, bit_str, backing, image_name]
        info = Chef::Config[:ec2_image_info][ keys ]
        ui.warn("Can't find image for #{[region, bit_str, backing, image_name].inspect}") if info.blank?
        return info || {}
      end

      def image_id
        result = read_attribute(:image_id) || image_info[:image_id]
      end

      def ssh_key_name(computer)
        keypair ? keypair.to_s : computer.server.cluster_name
      end

      def default_region
        default_availability_zone ? default_availability_zone.gsub(/^(\w+-\w+-\d)[a-z]/, '\1') : nil
      end

      def to_display(style,values={})
        return values if style == :minimal

        values["Flavor"] =            flavor
        values["AZ"] =                default_availability_zone
        return values if style == :default

        # values["Elastic IP"] =        public_ip if public_ip
        values["Elastic IP"] =        elastic_ip if elastic_ip
        values
      end

      def flavor_info
        if not Chef::Config[:ec2_flavor_info].has_key?(flavor)
          ui.warn("Unknown machine image flavor '#{flavor}'")
          list_flavors
          return nil
        end
        Chef::Config[:ec2_flavor_info][flavor]
      end

      def implied_volumes
        result = []
        if backing == 'ebs'
          result << Ironfan::Dsl::Volume.new(:name => 'root') do
            device              '/dev/sda1'
            fstype              'ext4'
            keep                false
            mount_point         '/'
          end
        end
        return result unless (mount_ephemerals and (flavor_info[:ephemeral_volumes] > 0))

        layout = {  0 => ['/dev/sdb','/mnt'],
                    1 => ['/dev/sdc','/mnt2'],
                    2 => ['/dev/sdd','/mnt3'],
                    3 => ['/dev/sde','/mnt4']   }
        ( 0 .. (flavor_info[:ephemeral_volumes]-1) ).each do |idx|
          dev, mnt = layout[idx]
          ephemeral = Ironfan::Dsl::Volume.new(:name => "ephemeral#{idx}") do
            attachable          'ephemeral'
            fstype              'ext3'
            device              dev
            mount_point         mnt
            mount_options       'defaults,noatime'
            tags({:bulk => true, :local => true, :fallback => true})
          end
          ephemeral.receive! mount_ephemerals
          result << ephemeral
        end
        result
      end

      def receive_provider(obj)
        if obj.is_a?(String)
          write_attribute :provider, Gorillib::Inflector.constantize(Gorillib::Inflector.camelize(obj.gsub(/\./, '/')))
        else
          super(obj)
        end
      end

      class SecurityGroup < Ironfan::Dsl
        field :name,                    String
        field :group_authorized,        Array, :default => []
        field :group_authorized_by,     Array, :default => []
        field :range_authorizations,    Array, :default => []

        def authorize_port_range(range, cidr_ip = '0.0.0.0/0', ip_protocol = 'tcp')
          range = (range .. range) if range.is_a?(Integer)
          range_authorizations << [range, cidr_ip, ip_protocol]
          range_authorizations.compact!
          range_authorizations.uniq!
        end

        def authorized_by_group(other_name)
          group_authorized_by << other_name.to_s
          group_authorized_by.compact!
          group_authorized_by.uniq!
        end

        def authorize_group(other_name)
          group_authorized << other_name.to_s
          group_authorized.compact!
          group_authorized.uniq!
        end
      end

      class ElasticLoadBalancer

        class HealthCheck < Ironfan::Dsl
          magic :ping_protocol,         String,      :default => 'HTTP'
          magic :ping_port,             Integer,     :default => 80
          magic :ping_path,             String,      :default => '/'
          magic :timeout,               Integer,     :default => 5
          magic :interval,              Integer,     :default => 30
          magic :unhealthy_threshold,   Integer,     :default => 2
          magic :healthy_threshold,     Integer,     :default => 10

          def target
            if %w[ HTTP HTTPS ].include?(self.ping_protocol)
              "#{self.ping_protocol}:#{self.ping_port}#{self.ping_path}"
            else
              "#{self.ping_protocol}:#{self.ping_port}"
            end
          end

          def to_fog
            health_check       = {
              'HealthyThreshold'   => healthy_threshold,
              'Timeout'            => timeout,
              'UnhealthyThreshold' => unhealthy_threshold,
              'Interval'           => interval,
              'Target'             => target
            }
          end

        end

        # SSL ciphers susceptible to the BEAST attack
        BEAST_VULNERABLE_CIPHERS = %w[
          Protocol-SSLv2
          ADH-AES128-SHA
          ADH-AES256-SHA
          ADH-CAMELLIA128-SHA
          ADH-CAMELLIA256-SHA
          ADH-DES-CBC-SHA
          ADH-DES-CBC3-SHA
          ADH-RC4-MD5
          ADH-SEED-SHA
          AES128-SHA
          AES256-SHA
          DES-CBC-MD5
          DES-CBC-SHA
          DES-CBC3-MD5
          DES-CBC3-SHA
          DHE-DSS-AES128-SHA
          DHE-DSS-AES256-SHA
          DHE-RSA-AES128-SHA
          DHE-RSA-AES256-SHA
          EDH-DSS-DES-CBC-SHA
          EDH-DSS-DES-CBC3-SHA
          EDH-RSA-DES-CBC-SHA
          EDH-RSA-DES-CBC3-SHA
          EXP-ADH-DES-CBC-SHA
          EXP-ADH-RC4-MD5
          EXP-DES-CBC-SHA
          EXP-EDH-DSS-DES-CBC-SHA
          EXP-EDH-RSA-DES-CBC-SHA
          EXP-KRB5-DES-CBC-MD5
          EXP-KRB5-DES-CBC-SHA
          EXP-KRB5-RC2-CBC-MD5
          EXP-KRB5-RC2-CBC-SHA
          EXP-RC2-CBC-MD5
          IDEA-CBC-SHA
          KRB5-DES-CBC-MD5
          KRB5-DES-CBC-SHA
          KRB5-DES-CBC3-MD5
          KRB5-DES-CBC3-SHA
          PSK-3DES-EDE-CBC-SHA
          PSK-AES128-CBC-SHA
          PSK-AES256-CBC-SHA
          RC2-CBC-MD5
        ]

        field  :name,               String
        field  :port_mappings,      Array, :default => []
        magic  :disallowed_ciphers, Array, :default => BEAST_VULNERABLE_CIPHERS
        member :health_check,       HealthCheck

        def map_port(load_balancer_protocol = 'HTTP', load_balancer_port = 80, internal_protocol = 'HTTP', internal_port = 80, iam_server_certificate = nil)
          port_mappings << [ load_balancer_protocol, load_balancer_port, internal_protocol, internal_port, iam_server_certificate ]
          port_mappings.compact!
          port_mappings.uniq!
        end

        def ssl_policy_to_fog
          result = Hash[ *disallowed_ciphers.collect { |c| [ c, false ] }.flatten ]
          return {
            :name       => Digest::MD5.hexdigest("#{disallowed_ciphers.sort.join('')}"),
            :attributes => result,
          }
        end

        def listeners_to_fog(cert_lookup)
          port_mappings.map do |pm|
            result = {
              'Protocol'         => pm[0], # load_balancer_protocl
              'LoadBalancerPort' => pm[1], # load_balancer_port
              'InstanceProtocol' => pm[2], # internal_protocol
              'InstancePort'     => pm[3], # internal_port
            }
            result['SSLCertificateId'] = cert_lookup[pm[4]] if pm[4]
            result
          end
        end

      end

      # Although it is unreasonable to talk about an IAM Server Certificate object
      # without a certificate or private_key field value, we also allow users to
      # simply specify the arn of an existing IAM Server Certificate so that their
      # web server certificate is not required to be present in their recipes repo,
      # for security purposes. In that case the :arn field would be non-nil while
      # the :certificate and :private_key fields would be nil, which hints to the
      # EC2 Provider code that it should attempt to validate the existence of the
      # IAM Server Certificate in the EC2 cloud rather than trying to create it.
      class IamServerCertificate < Ironfan::Dsl
        field  :name,                   String
        magic  :arn,                    String,                         :default => nil
        magic  :certificate,            String,                         :default => nil # Actually a PEM encoding
        magic  :private_key,            String,                         :default => nil # Actually a PEM encoding
        magic  :certificate_chain,      String,                         :default => nil # Actually a PEM encoding
      end

    end

  end
end

Chef::Config[:ec2_flavor_info] ||= {}
Chef::Config[:ec2_flavor_info].merge!({
    # 32-or-64: m1.small, m1.medium, t1.micro, c1.medium
    't1.micro'    => { :price => 0.02,  :bits => 64, :ram =>    686, :cores => 1, :core_size => 0.25, :inst_disks => 0, :inst_disk_size =>    0, :ephemeral_volumes => 0 },
    'm1.small'    => { :price => 0.08,  :bits => 64, :ram =>   1740, :cores => 1, :core_size => 1,    :inst_disks => 1, :inst_disk_size =>  160, :ephemeral_volumes => 1 },
    'm1.medium'   => { :price => 0.165, :bits => 32, :ram =>   3840, :cores => 2, :core_size => 1,    :inst_disks => 1, :inst_disk_size =>  410, :ephemeral_volumes => 1 },
    'c1.medium'   => { :price => 0.17,  :bits => 32, :ram =>   1740, :cores => 2, :core_size => 2.5,  :inst_disks => 1, :inst_disk_size =>  350, :ephemeral_volumes => 1 },
    #
    'm1.large'    => { :price => 0.32,  :bits => 64, :ram =>   7680, :cores => 2, :core_size => 2,    :inst_disks => 2, :inst_disk_size =>  850, :ephemeral_volumes => 2 },
    'm2.xlarge'   => { :price => 0.45,  :bits => 64, :ram =>  18124, :cores => 2, :core_size => 3.25, :inst_disks => 1, :inst_disk_size =>  420, :ephemeral_volumes => 1 },
    'c1.xlarge'   => { :price => 0.64,  :bits => 64, :ram =>   7168, :cores => 8, :core_size => 2.5,  :inst_disks => 4, :inst_disk_size => 1690, :ephemeral_volumes => 4 },
    'm1.xlarge'   => { :price => 0.66,  :bits => 64, :ram =>  15360, :cores => 4, :core_size => 2,    :inst_disks => 4, :inst_disk_size => 1690, :ephemeral_volumes => 4 },
    'm2.2xlarge'  => { :price => 0.90,  :bits => 64, :ram =>  35020, :cores => 4, :core_size => 3.25, :inst_disks => 2, :inst_disk_size =>  850, :ephemeral_volumes => 2 },
    'm2.4xlarge'  => { :price => 1.80,  :bits => 64, :ram =>  70041, :cores => 8, :core_size => 3.25, :inst_disks => 4, :inst_disk_size => 1690, :ephemeral_volumes => 4 },
    'cc1.4xlarge' => { :price => 1.30,  :bits => 64, :ram =>  23552, :cores => 8, :core_size => 4.19, :inst_disks => 4, :inst_disk_size => 1690, :ephemeral_volumes => 2, :placement_groupable => true, :virtualization => 'hvm' },
    'cc1.8xlarge' => { :price => 2.40,  :bits => 64, :ram =>  61952, :cores =>16, :core_size => 5.50, :inst_disks => 8, :inst_disk_size => 3370, :ephemeral_volumes => 4, :placement_groupable => true, :virtualization => 'hvm' },
    'cg1.4xlarge' => { :price => 2.10,  :bits => 64, :ram =>  22528, :cores => 8, :core_size => 4.19, :inst_disks => 4, :inst_disk_size => 1690, :ephemeral_volumes => 2, :placement_groupable => true, :virtualization => 'hvm' },
  })

Chef::Config[:ec2_image_info] ||= {}
Chef::Config[:ec2_image_info].merge!({
  #
  # Lucid (Ubuntu 9.10)
  #
  %w[us-east-1             64-bit  instance        karmic     ] => { :image_id => 'ami-55739e3c', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[us-east-1             32-bit  instance        karmic     ] => { :image_id => 'ami-bb709dd2', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[us-west-1             64-bit  instance        karmic     ] => { :image_id => 'ami-cb2e7f8e', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[us-west-1             32-bit  instance        karmic     ] => { :image_id => 'ami-c32e7f86', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[eu-west-1             64-bit  instance        karmic     ] => { :image_id => 'ami-05c2e971', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[eu-west-1             32-bit  instance        karmic     ] => { :image_id => 'ami-2fc2e95b', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },

  #
  # Lucid (Ubuntu 10.04.3)
  #
  %w[ap-southeast-1        64-bit  ebs             lucid      ] => { :image_id => 'ami-77f28d25', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ap-southeast-1        32-bit  ebs             lucid      ] => { :image_id => 'ami-4df28d1f', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ap-southeast-1        64-bit  instance        lucid      ] => { :image_id => 'ami-57f28d05', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ap-southeast-1        32-bit  instance        lucid      ] => { :image_id => 'ami-a5f38cf7', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[eu-west-1             64-bit  ebs             lucid      ] => { :image_id => 'ami-ab4d67df', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[eu-west-1             32-bit  ebs             lucid      ] => { :image_id => 'ami-a94d67dd', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[eu-west-1             64-bit  instance        lucid      ] => { :image_id => 'ami-a54d67d1', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[eu-west-1             32-bit  instance        lucid      ] => { :image_id => 'ami-cf4d67bb', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  #
  %w[us-east-1             64-bit  ebs             lucid      ] => { :image_id => 'ami-4b4ba522', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[us-east-1             32-bit  ebs             lucid      ] => { :image_id => 'ami-714ba518', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[us-east-1             64-bit  instance        lucid      ] => { :image_id => 'ami-fd4aa494', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[us-east-1             32-bit  instance        lucid      ] => { :image_id => 'ami-2d4aa444', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  #
  %w[us-west-1             64-bit  ebs             lucid      ] => { :image_id => 'ami-d197c694', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[us-west-1             32-bit  ebs             lucid      ] => { :image_id => 'ami-cb97c68e', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[us-west-1             64-bit  instance        lucid      ] => { :image_id => 'ami-c997c68c', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[us-west-1             32-bit  instance        lucid      ] => { :image_id => 'ami-c597c680', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },

  #
  # Maverick (Ubuntu 10.10)
  #
  %w[ ap-southeast-1       64-bit  ebs             maverick   ] => { :image_id => 'ami-32423c60', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ ap-southeast-1       64-bit  instance        maverick   ] => { :image_id => 'ami-12423c40', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ ap-southeast-1       32-bit  ebs             maverick   ] => { :image_id => 'ami-0c423c5e', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ ap-southeast-1       32-bit  instance        maverick   ] => { :image_id => 'ami-7c423c2e', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  #
  %w[ eu-west-1            64-bit  ebs             maverick   ] => { :image_id => 'ami-e59ca991', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ eu-west-1            64-bit  instance        maverick   ] => { :image_id => 'ami-1b9ca96f', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ eu-west-1            32-bit  ebs             maverick   ] => { :image_id => 'ami-fb9ca98f', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ eu-west-1            32-bit  instance        maverick   ] => { :image_id => 'ami-339ca947', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  #
  %w[ us-east-1            64-bit  ebs             maverick   ] => { :image_id => 'ami-cef405a7', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ us-east-1            64-bit  instance        maverick   ] => { :image_id => 'ami-08f40561', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ us-east-1            32-bit  ebs             maverick   ] => { :image_id => 'ami-ccf405a5', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ us-east-1            32-bit  instance        maverick   ] => { :image_id => 'ami-a6f504cf', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  #
  %w[ us-west-1            64-bit  ebs             maverick   ] => { :image_id => 'ami-af7e2eea', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ us-west-1            64-bit  instance        maverick   ] => { :image_id => 'ami-a17e2ee4', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ us-west-1            32-bit  ebs             maverick   ] => { :image_id => 'ami-ad7e2ee8', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ us-west-1            32-bit  instance        maverick   ] => { :image_id => 'ami-957e2ed0', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },

  #
  # Natty (Ubuntu 11.04)
  #
  %w[ ap-northeast-1       32-bit  ebs             natty      ] => { :image_id => 'ami-00b10501', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ ap-northeast-1       32-bit  instance        natty      ] => { :image_id => 'ami-f0b004f1', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ ap-northeast-1       64-bit  ebs             natty      ] => { :image_id => 'ami-02b10503', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ ap-northeast-1       64-bit  instance        natty      ] => { :image_id => 'ami-fab004fb', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  #
  %w[ ap-southeast-1       32-bit  ebs             natty      ] => { :image_id => 'ami-06255f54', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ ap-southeast-1       32-bit  instance        natty      ] => { :image_id => 'ami-72255f20', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ ap-southeast-1       64-bit  ebs             natty      ] => { :image_id => 'ami-04255f56', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ ap-southeast-1       64-bit  instance        natty      ] => { :image_id => 'ami-7a255f28', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  #
  %w[ eu-west-1            32-bit  ebs             natty      ] => { :image_id => 'ami-a4f7c5d0', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ eu-west-1            32-bit  instance        natty      ] => { :image_id => 'ami-fef7c58a', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ eu-west-1            64-bit  ebs             natty      ] => { :image_id => 'ami-a6f7c5d2', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ eu-west-1            64-bit  instance        natty      ] => { :image_id => 'ami-c0f7c5b4', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  #
  %w[ us-east-1            32-bit  ebs             natty      ] => { :image_id => 'ami-e358958a', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ us-east-1            32-bit  instance        natty      ] => { :image_id => 'ami-c15994a8', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ us-east-1            64-bit  ebs             natty      ] => { :image_id => 'ami-fd589594', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ us-east-1            64-bit  instance        natty      ] => { :image_id => 'ami-71589518', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  #
  %w[ us-west-1            32-bit  ebs             natty      ] => { :image_id => 'ami-43580406', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ us-west-1            32-bit  instance        natty      ] => { :image_id => 'ami-e95f03ac', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ us-west-1            64-bit  ebs             natty      ] => { :image_id => 'ami-4d580408', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ us-west-1            64-bit  instance        natty      ] => { :image_id => 'ami-a15f03e4', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },

  #
  # Cluster Compute
  #
  # IMAGE   ami-6d2ce204    205199409180/Globus Provision 0.4.AMI (Ubuntu 11.04 HVM)            205199409180    available       public          x86_64  machine                 ebs             hvm             xen
  #
  %w[ us-east-1            64-bit  ebs             natty-cc   ] => { :image_id => 'ami-6d2ce204', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },

  #
  # Oneiric (Ubuntu 11.10)
  #
  %w[ ap-northeast-1       32-bit  ebs             oneiric    ] => { :image_id => 'ami-84902785', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ ap-northeast-1       32-bit  instance        oneiric    ] => { :image_id => 'ami-5e90275f', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ ap-northeast-1       64-bit  ebs             oneiric    ] => { :image_id => 'ami-88902789', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ ap-northeast-1       64-bit  instance        oneiric    ] => { :image_id => 'ami-7c90277d', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  #
  %w[ ap-southeast-1       32-bit  ebs             oneiric    ] => { :image_id => 'ami-0a327758', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ ap-southeast-1       32-bit  instance        oneiric    ] => { :image_id => 'ami-00327752', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ ap-southeast-1       64-bit  ebs             oneiric    ] => { :image_id => 'ami-0832775a', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ ap-southeast-1       64-bit  instance        oneiric    ] => { :image_id => 'ami-04327756', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  #
  %w[ eu-west-1            32-bit  ebs             oneiric    ] => { :image_id => 'ami-11f0cc65', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ eu-west-1            32-bit  instance        oneiric    ] => { :image_id => 'ami-4ff0cc3b', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ eu-west-1            64-bit  ebs             oneiric    ] => { :image_id => 'ami-1df0cc69', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ eu-west-1            64-bit  instance        oneiric    ] => { :image_id => 'ami-23f0cc57', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  #
  %w[ us-east-1            32-bit  ebs             oneiric    ] => { :image_id => 'ami-a562a9cc', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ us-east-1            32-bit  instance        oneiric    ] => { :image_id => 'ami-3962a950', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ us-east-1            64-bit  ebs             oneiric    ] => { :image_id => 'ami-bf62a9d6', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ us-east-1            64-bit  instance        oneiric    ] => { :image_id => 'ami-c162a9a8', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  #
  %w[ us-west-1            32-bit  ebs             oneiric    ] => { :image_id => 'ami-c9a1fe8c', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ us-west-1            32-bit  instance        oneiric    ] => { :image_id => 'ami-21a1fe64', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ us-west-1            64-bit  ebs             oneiric    ] => { :image_id => 'ami-cba1fe8e', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ us-west-1            64-bit  instance        oneiric    ] => { :image_id => 'ami-3fa1fe7a', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  #
  %w[ us-west-2            32-bit  ebs             oneiric    ] => { :image_id => 'ami-ea9a17da', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ us-west-2            32-bit  instance        oneiric    ] => { :image_id => 'ami-f49a17c4', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ us-west-2            64-bit  ebs             oneiric    ] => { :image_id => 'ami-ec9a17dc', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ us-west-2            64-bit  instance        oneiric    ] => { :image_id => 'ami-fe9a17ce', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },


  #
  # Precise (Ubuntu 11.10)
  #
  %w[ us-east-1            32-bit  ebs             precise    ] => { :image_id => 'ami-3b4ff252', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  %w[ us-east-1            64-bit  ebs             precise    ] => { :image_id => 'ami-3d4ff254', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  # # These images will only work once http://askubuntu.com/questions/209844/latest-ec2-ubuntu-instance-seems-broken is fixed
  # %w[ us-east-1            32-bit  ebs             precise    ] => { :image_id => 'ami-9878c0f1', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
  # %w[ us-east-1            64-bit  ebs             precise    ] => { :image_id => 'ami-9c78c0f5', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
})
