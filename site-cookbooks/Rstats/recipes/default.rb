
%w[r-base r-base-dev].each do |pkg|
  package pkg do
    action :install
  end
end

gem_package "rsruby" do
  options "-- --with-R-dir=/usr/share/R --with-R-lib=/usr/lib/R --with-R-include=/usr/share/R/include"
  action :install
end


# Once R is installed you'll want to install some essential packages like VGAM and ggplot, ie. install.packages('VGAM')
bash "Installing r packages" do
  code %Q{ export R_HOME=/usr/lib/R ; echo 'install.packages(c("VGAM", "ggplot2"))' | Rscript --verbose - }
end
