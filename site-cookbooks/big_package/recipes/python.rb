
package "python" do
  action :install
end

%w{
  dev imaging matplotlib matplotlib-data matplotlib-doc mysqldb
  numpy numpy-ext paramiko scipy setuptools sqlite
 simplejson
}.each do |pkg|
  package "python-#{pkg}" do
    action :install
  end
end

%w{
 boto ctypedbytes dumbo
}.each do |pkg|
  easy_install_package pkg do
    action :install
  end
end

