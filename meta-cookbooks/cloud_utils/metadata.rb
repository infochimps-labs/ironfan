maintainer       "Philip (flip) Kromer - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.3"

description      "Grabbag of utility cookbooks"

depends          "runit"

recipe           "cloud_utils::burn_ami_prep",        "Burn Ami Prep"
recipe           "cloud_utils::virtualbox_metadata",  "Virtualbox Metadata"

%w[ debian ubuntu ].each do |os|
  supports os
end
