package "python" do
  action :install
end

%w[
  dev mysqldb
  setuptools sqlite
  simplejson
].each do |pkg|
  package "python-#{pkg}" do
    action :install
  end
end

# ctypedbytes
# %w[
#  boto dumbo
# ].each do |pkg|
#   easy_install_package pkg do
#     action :install
#   end
# end

