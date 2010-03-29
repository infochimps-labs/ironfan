# unscrewup the hostname every way I can think of
sudo hostname chefclient.infinitemonkeys.info           ;
sudo sed -i 's/127.0.0.1 localhost/127.0.0.1 chefclient.infinitemonkeys.info localhost/' /etc/hosts ;
sudo bash -c 'echo "184.72.52.30 chefclient.infinitemonkeys.info " >> /etc/hosts' ;
sudo bash -c 'echo "chefclient.infinitemonkeys.info" > /etc/hostname' ;
sudo sysctl -w kernel.hostname=chefclient.infinitemonkeys.info ;

# Broaden the apt universe
sudo sed -i 's/universe/multiverse universe/' /etc/apt/sources.list
sudo bash -c 'echo "deb http://us.archive.ubuntu.com/ubuntu karmic main restricted"     >> /etc/apt/sources.list ';
sudo bash -c 'echo "deb http://us.archive.ubuntu.com/ubuntu karmic universe multiverse" >> /etc/apt/sources.list ';
sudo apt-get -y update  ;
sudo apt-get -y upgrade ;
sudo apt-get -f install ;

# this runs interactively, so get ready with the any key.  (hit tab-enter tab-enter to accept the sun license)
sudo apt-get install -y sun-java6-jre sun-java6-jdk g++ emacs23-nox ec2-api-tools ec2-ami-tools ;

# base packages
sudo apt-get install -y ruby ruby1.8-dev libopenssl-ruby1.8 rubygems ri irb build-essential wget ssl-cert git-core zlib1g-dev libxml2-dev ;
# unchain rubygems from the tyrrany of ubuntu
sudo gem install --no-rdoc --no-ri rubygems-update --version=1.3.6 ; sudo /var/lib/gems/1.8/bin/update_rubygems; sudo gem update --no-rdoc --no-ri --system ; gem --version ;
sudo gem install --no-rdoc --no-ri rdoc rake

# Merb 1.1.0 is too awesome for the chef-server-webui.  Force install the 1.0.15 versions first
sudo gem install --no-rdoc --no-ri --version=1.0.15 merb-core merb-assets merb-haml merb-helpers merb-param-protection merb-slices

# install chef and bootstrap it
sudo gem install --no-rdoc --no-ri chef ;
# In case it tries to install a newer merb-core
sudo gem uninstall --no-executables --version=1.1.0 --ignore-dependencies merb-core

wget https://gist.github.com/raw/6b48b6ce9bb13ec2138a/1e2e1fc92729f092eea378923f9e0edeef3f3bc4/chef.json -O /tmp/chef.json ;
wget https://gist.github.com/raw/6b48b6ce9bb13ec2138a/2b48849607fa7aed7bc771c40e0cc79293e12dae/solo.rb   -O /tmp/solo.rb   ;
sudo chef-solo -c /tmp/solo.rb -j /tmp/chef.json ;

# scp flip@mrflip.dyndns.org:/tmp/\*.pem /tmp/^
# sudo chown root:root /etc/chef/validation.pem ; sudo chmod og-rwx /etc/chef/validation.pem
sudo service chef-client restart

# cleanup
sudo apt-get autoremove; 
sudo updatedb;
