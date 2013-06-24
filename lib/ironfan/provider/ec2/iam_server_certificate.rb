module Ironfan
  class Provider
    class Ec2

      # Fog::AWS doesn't seem to have native models for IAM ServerCertificate
      #   using Hash semantics instead
      class IamServerCertificate < Ironfan::Provider::Resource
        delegate :[],:[]=, :to => :adaptee

        ARN_PREFIX = "iamss_arn"

        def self.shared?()       true;   end
        def self.multiple?()     true;   end
        def self.resource_type() :iam_server_certificate;   end
        def self.expected_ids(computer)
          ec2 = computer.server.cloud(:ec2)
          ec2.iam_server_certificates.values.map do |cert|
            self.expected_id(computer, cert)
          end
        end

        def name()
          self['ServerCertificateName']
        end

        #
        # Discovery
        #
        def self.load!(cluster=nil)
          Ec2.iam.list_server_certificates.body['Certificates'].each do |cert|
            iss = new(:adaptee => cert)
            remember(iss, { :id => cert['ServerCertificateName'] })
            remember(iss, { :id => "#{ARN_PREFIX}:#{cert['Arn']}" })
          end
        end

        def to_s
          "<%-20s %-32s>" % [ self['ServerCertificateName'], self['Arn']]
        end

        #
        # Manipulation
        #

        # Create any certificates that are needed by any clouds in which there are running computers
        def self.aggregate!(computers)
          ec2_computers = computers.select { |c| Ec2.applicable c }
          return if ec2_computers.empty?

          load! # Find out which certificates already exist in EC2
          certs_for_running_servers = ec2_computers.select { |c| c.running? }.map { |c| self.expected_ids(c) }.flatten.uniq
          certs_for_stopped_servers = ec2_computers.select { |c| not c.running? }.map { |c| self.expected_ids(c) }.flatten.uniq
          certs_to_start = [ certs_for_running_servers ].flatten.compact.reject { |cert_name| recall? cert_name }
          certs_to_stop  = [ certs_for_stopped_servers - certs_for_running_servers ].flatten.compact.select { |cert_name| recall? cert_name }

          certs_to_start.each do |cert_name|
            if cert_name =~ /^#{ARN_PREFIX}:(.+)$/
              error = "Cannot create an IAM server certificate with an explicit ARN #{$1}. Explicit ARNs can only be used to capture existing IAM server certificates created outside of Ironfan."
              puts error and raise error
            else
              Ironfan.step(cert_name, "creating server certificate", :blue)
              computer  = ec2_computers.select { |c| self.expected_ids(c).include?(cert_name) }.values.first
              use_name  = cert_name.sub("ironfan-#{computer.server.cluster_name}-", '')
              cert_prov = computer.server.cloud(:ec2).iam_server_certificates[use_name]
              options   = cert_prov.certificate_chain.nil? ? { } : { 'CertificateChain' => cert_prov.certificate_chain }
              Ec2.iam.upload_server_certificate(cert_prov.certificate, cert_prov.private_key, cert_name, options)
            end
          end

          certs_to_stop.each do |cert_name|
            if cert_name !~ /^#{ARN_PREFIX}:(.+)$/
              Ironfan.step(cert_name, "appears to be unused; you may want to remove it manually", :red)
            end
          end

          load! # Get new list of native certificates via reload
        end

        def self.full_name(computer, cert)
          "ironfan-%s-%s" % [ computer.server.cluster_name, cert.name ]
        end

        def self.expected_id(computer, cert)
          n = self.full_name(computer, cert)
          if cert.arn
            Chef::Log.info("Using explicit IAMServerCertificate ARN #{cert.arn} instead of inferred name #{n}")
            "#{ARN_PREFIX}:#{cert.arn}"
          else
            if n.length > 32
              error = "Excessively long certificate name #{n}, must be <= 32 characters"
              puts error and raise error
            end
            n
          end
        end

      end
    end
  end
end
