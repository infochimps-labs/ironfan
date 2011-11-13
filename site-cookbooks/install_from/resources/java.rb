class_from_file ::File.expand_path('package.rb', ::File.dirname(__FILE__))

# sets the JAVA_HOME environment variable for the ant run
attribute :java_home, :kind_of => String
