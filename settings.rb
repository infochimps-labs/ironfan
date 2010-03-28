require 'configliere'
Configliere.use :config_file
Settings.read File.join(ENV['HOME'],'.poolparty','aws'); Settings.resolve!
