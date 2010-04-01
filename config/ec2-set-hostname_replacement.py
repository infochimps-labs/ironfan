#!/usr/bin/python
#
#    Set instance hostname to the localhostname defined by the EC2 meta-data
#    service
#    Copyright (C) 2008-2009 Canonical Ltd.
#
#    Authors: Chuck Short <chuck.short@canonical.com>
#             Soren Hansen <soren@canonical.com>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License version 3, as
#    published by the Free Software Foundation.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
import subprocess
import ec2init
import os.path

def main():
    if os.path.exists("/etc/hostname"):
        # print "Setting hostname from /etc/hostname"
        subprocess.Popen(['hostname', '-F', "/etc/hostname"]).communicate()
    else:
        ec2 = ec2init.EC2Init()
        hostname = ec2.get_hostname()
        # print "Read hostname from ec2 local hostname: " + hostname
        subprocess.Popen(['hostname', hostname]).communicate()

if __name__ == '__main__':
    main()
