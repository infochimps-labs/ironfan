# Managing Elastic Load Balancers with Ironfan

## Example

    Ironfan.cluster "sparky" do

      cloud(:ec2) do
        # This certificate can be defined at a cluster or facet level.
        # However, the last call wins if the same attribute is defined
        # in more than one context.
        iam_server_certificate "snake-oil" do
          certificate       IO.read('snakeoil.crt')
          private_key       IO.read('snakeoil.key')
          certificate_chain IO.read('snakeoil.crt.bundle') # optional
        end
      end

      facet :web do
        instances 2
        cloud(:ec2) do

          elastic_load_balancer "sparky-elb" do
            map_port('HTTP',   80, 'HTTP', 81)

            # This SSL listener uses the certificate defined above
            map_port('HTTPS', 443, 'HTTP', 81, 'snake-oil')

            # Applies to all HTTPS/SSL listeners
            allowed_ciphers(%w[ Protocol-SSLv3 Protocol-TLSv1 RC4-MD5 RC4-SHA ])

            # If AWS tries to add other ciphers automatically because "they know
            # best", and you really don't want that cipher (e.g. the cipher is
            # flagged as problematic by SSLLabs, nessus, etc.) you can explicitly
            # disallow the cipher from your HTTPS/SSL listeners thusly.
            disallowed_ciphers(%w[ AES128-SHA ])
            # PROTIP: The disallowed_ciphers call is usually unnecessary

            # Enable the cross-zone load balancing feature so traffic is
            # evenly distributed across servers regardless of their availability
            # zone
            cross_zone_load_balancing true

            # Health check that is made against ALL running instances
            health_check do
              ping_protocol       'HTTP'
              ping_port           82
              ping_path           '/healthcheck'
              timeout             4
              interval            10
              unhealthy_threshold 3
              healthy_threshold   2
            end
          end

        end
      end
    end

## Uploading your certificate

There are two ways to supply your certificate to Ironfan. The first is to make the certificate, private key, and (optionally) certificate chain data readable by Ruby code in your cluster file.

    iam_server_certificate "snake-oil" do
      certificate       IO.read('snakeoil.crt')
      private_key       IO.read('snakeoil.key')
      certificate_chain IO.read('snakeoil.crt.bundle') # optional
    end

Having your server certificates persistently available in your ironfan-homebase might not be optimal, so you can simply specify the ARN of the existing IAM server certificate:

    iam_server_certificate "snake-oil" do
      arn 'arn:aws:iam::782698214375:server-certificate/ironfan-sparky-snake-oil'
    end

## When are Certificates and ELBs updated?

Your server certificates and ELBs are only relevant when there are server instances present to service them. Therefore, the following logic is applied to decide when to synchronize or update your certificate/ELB configuration:

### bootstrap, kill, launch, start, stop, sync

When one of these `knife cluster` actions finishes, the Ironfan code will examine the up-to-date list of running servers to see if there are any ELBs that are now needed, or which are no longer needed. In support of these feature, any required certificate uploads, health check modifications, SSL policy updates, or listener modifications will be performed as well.

If an ELB is no longer needed, it will be destroyed **but any corresponding certificates will not be destroyed**. This is a convenience for system administrators who want to load their sensitive/precious certificates into AWS just once, and is intended to be used in conjunction with the `iam_server_certificate.arn` attribute.

(To get a list of existing ARNs, try the [IAM Command Line Toolkit](http://aws.amazon.com/developertools/AWS-Identity-and-Access-Management/4143) provided by AWS.)

### kick, list, proxy, pry, show, ssh

These `knife cluster` commands are not associated with updates of the Chef or IAAS configurations of your server instances, so no certificate or ELB modifications occur after these commands complete.

## SSL policy

The SSL policy control in Ironfan is very rudimentary. You may control which ciphers are explicitly allowed or disallowed as follows

    elastic_load_balancer "sparky-elb" do
      ...
      allowed_ciphers(%w[ Protocol-SSLv3 Protocol-TLSv1 RC4-MD5 RC4-SHA ])
      disallowed_ciphers(%w[ AES128-SHA ])
      ...
    end

Note that the default behavior is to allow a standard "safe" list of ciphers supported by most modern browsers, and to disallow ciphers that are hypothetically vulnerable to the [BEAST attack](http://vnhacker.blogspot.com/2011/09/beast.html) and RC4 attacks (http://en.wikipedia.org/wiki/Transport_Layer_Security#RC4_attacks). You probably don't want or need to change it.

NOTE: If you do call allowed_ciphers or disallowed_ciphers, you will be overriding the built-in defaults and will need to specify the complete list of allowed or disallowed ciphers instead of just the ones you want to add or remove from the list.

## Cross-zone load balancing

This defaults to false, which is AWS's default.  Setting it to true will tell the ELB to distribute load evenly across all instances, instead of balancing across availability zones.  [Cross-Zone Load Balancing](http://aws.amazon.com/about-aws/whats-new/2013/11/06/elastic-load-balancing-adds-cross-zone-load-balancing/)

## How do port mappings work?

A port mapping is a mapping between a TCP port on the ELB and a TCP port on your instance. A request arriving at _external_port_number_ on your ELB will be negotiated using the _external_protocol_, and will be forwarded to the _internal_port_ on one of your instances using _internal_protocol_.

If _external_protocol_ is 'HTTPS' and _internal_protocol_ is 'HTTP' (which is referred to as "SSL termination" at the ELB), you'll probably want to know that in your server code. ELBs set the header [X-Forwarded-Proto](http://en.wikipedia.org/wiki/List_of_HTTP_header_fields) to let you know what protocol was used to connect to the ELB. Awareness of that header in your server allows you to aboid redirect loops if, for example, your code insists that clients connect over HTTPS.

The format of the map_port call is as follows:

    map_port(external_protocol, external_port_number, internal_protocol, internal_port_number [, certificate])

You'll need a certificate if the _external\_protocol_ is 'HTTPS' or 'SSL'. It will be ignored otherwise.

Your one-and-only SSL policy (probably the BEAST-defeating default) will be applied to all port mappings with certificates.

## Other policies

The Ironfan ELB code does not support other types of listener policies. Please contact me using the information below if you need other types of policy support.

## VPC support

There is no explicit VPC support in this code. If you need to use Ironfan-based ELBs in a VPC context and find that this code doesn't give you what you need, please submit an issue or, better yet, a pull request.

## Spanning facets

An ELB **can** be declared at the cluster level rather than the facet level, but that's a weird thing to do. But don't let me tell you not to be weird!

Note that since each ELB has only one health check, it would need to be the case that your servers in each facet could respond to the same health check request. If they can, they should probably be members of the same facet.

# Contact me

This feature was initially created by [Nick Marden](https://github.com/nickmarden). I'd love your feedback and suggestions.
