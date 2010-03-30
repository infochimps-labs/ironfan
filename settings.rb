require 'configliere'
Configliere.use :config_file
Settings.read File.join(ENV['HOME'],'.poolparty','aws'); Settings.resolve!

AMIS = {
  :canonical_ubuntu_910 => {
    :x32_useast1_ebs => 'ami-6743ae0e',
    :x64_useast1_ebs => 'ami-7d43ae14',
    :x32_uswest1_ebs => 'ami-fd5100b8',
    :x64_uswest1_ebs => 'ami-ff5100ba',
    :x32_useast1_s3  => 'ami-bb709dd2',
    :x64_useast1_s3  => 'ami-55739e3c',
    :x32_uswest1_s3  => 'ami-c32e7f86',
    :x64_uswest1_s3  => 'ami-cb2e7f8e',
  },
  :canonical_ubuntu_lucid_daily => {
    :x32_uswest1_ebs  => 'ami-07613042',
  },
  #
  :infochimps_ubuntu_910 => {
    :x32_uswest1_ebs_a  => 'ami-d7613092',
    :x32_uswest1_ebs_b => 'ami-e16130a4',
    :x32_uswest1_ebs_hadoop_a => 'ami-6b60312e',
    :x32_uswest1_ebs_hadoop_b => 'ami-e16031a4',
  },
}
