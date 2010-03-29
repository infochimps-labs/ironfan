# # Sets up small website on cluster.
# # TODO(philip): Add links/documentation.
# function setup_web() {
#
#   if which dpkg &> /dev/null; then
#     apt-get -y install thttpd
#     WWW_BASE=/var/www
#   elif which rpm &> /dev/null; then
#     yum install -y thttpd
#     chkconfig --add thttpd
#     WWW_BASE=/var/www/thttpd/html
#   fi
#
#   cat > $WWW_BASE/index.html << END
# <html>
# <head>
# <title>Hadoop EC2 Cluster</title>
# </head>
# <body>
# <h1>Hadoop EC2 Cluster</h1>
# To browse the cluster you need to have a proxy configured.
# Start the proxy with <tt>hadoop-ec2 proxy &lt;cluster_name&gt;</tt>,
# and point your browser to
# <a href="http://cloudera-public.s3.amazonaws.com/ec2/proxy.pac">this Proxy
# Auto-Configuration (PAC)</a> file.  To manage multiple proxy configurations,
# you may wish to use
# <a href="https://addons.mozilla.org/en-US/firefox/addon/2464">FoxyProxy</a>.
# <ul>
# <li><a href="http://$MASTER_HOST:50070/">NameNode</a>
# <li><a href="http://$MASTER_HOST:50030/">JobTracker</a>
# <li><a href="http://$MASTER_HOST:8088/">Cloudera Desktop</a>
# </ul>
# </body>
# </html>
# END
#
#   service thttpd start
#
# }
