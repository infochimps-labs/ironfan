Does the fetch-unpack-configure-build-install dance.

Given a project `pig`, with url `http://apache.org/pig/pig-0.8.0.tar.gz`, and
the default :root_dir of `/usr/local`, this provider will

* fetch  it to :package_file (`/usr/local/src/pig-0.8.0.tar.gz`)
* unpack it to :install_dir  (`/usr/local/share/pig-0.8.0`)
* create a symlink for :home_dir (`/usr/local/share/pig`) pointing to :install_dir
* configure the project
* build the project
* install the project
