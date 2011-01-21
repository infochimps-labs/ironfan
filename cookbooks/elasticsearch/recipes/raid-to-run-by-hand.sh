#!/bin/false

# run this by hand -- and watch carefully

for foo in chef-client elasticsearch nginx ; do echo $foo ; sudo service $foo stop  ; done

sudo apt-get -y install mdadm

for foo in /dev/sd{b,c,d,e} ; do echo $foo ; sudo umount $foo ; done

echo -e '1\np\nn\np\n1\n1\n\nt\nfd\nw\n' | sudo fdisk /dev/sdb
echo -e '1\np\nn\np\n1\n1\n\nt\nfd\nw\n' | sudo fdisk /dev/sdc
echo -e '1\np\nn\np\n1\n1\n\nt\nfd\nw\n' | sudo fdisk /dev/sdd
echo -e '1\np\nn\np\n1\n1\n\nt\nfd\nw\n' | sudo fdisk /dev/sde
sudo partprobe
sudo fdisk -l
sudo bash -c 'echo "15000" > /proc/sys/dev/raid/speed_limit_min'
sudo mdadm --create /dev/md0 --level 0 --raid-devices 4 /dev/sdb1 /dev/sdc1 /dev/sdd1 /dev/sde1

sudo mkfs.xfs -L raid /dev/md0

sudo mv /etc/mdadm/mdadm.conf  /etc/mdadm/mdadm.conf.orig
sudo bash -c 'echo "DEVICE /dev/hd*[0-9] /dev/sd*[0-9]" > /etc/mdadm/mdadm.conf'
sudo bash -c 'mdadm --detail --scan >> /etc/mdadm/mdadm.conf'

sudo bash -c 'echo "/dev/md0                                        /mnt            xfs     defaults,nobootwait,comment=cloudconfig      0     2" >> /etc/fstab '
sudo nano /etc/fstab

sudo mount /mnt
