#!/bin/sh

# see http://fossplanet.com/f10/[ec2ubuntu]-not-starting-nfs-kernel-daemon-no-support-current-kernel-90948/

set -v

# on x86_64 there is a '-server' kernel, on i386, it is '-generic-pae'
flav="server"
[ "$(uname -m)" = "x86_64" ] || flav="generic-pae"
sver=$(uname -r)
sver=${sver%-*} # remove '-virtual', sver will be like '2.6.35-22'
sdir=/lib/modules/${sver}-${flav}
tdir=/lib/modules/${sver}-virtual
module="nfsd"

echo $flav $sver $sdir $tdir $module

sudo apt-get install -y linux-image-${sver}-server

# parse modules.dep to get which modules $module depends on
nfsmods=$(sed -n -e "\|/${module}.ko:|"'!'"d" -e 's,:,,p' "${sdir}/modules.dep")

for m in ${nfsmods}; do
[ -f "${tdir}/${m}" ] && { echo "${m} already existed"; continue; }
echo "${m} -> ${tdir}/${m%/*}"
sudo mkdir -p "${tdir}/${m%/*}"

sudo cp -a "${sdir}/${m}" "${tdir}/${m}"
done

sudo depmod -a

sudo modprobe nfsd

sudo apt-get install -y nfs-kernel-server

sudo service nfs-kernel-server restart

echo -e "\n\n *******\nYou must restart the server for NFS to actuate\n\n *****\n"

#### END #####
