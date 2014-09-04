# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ironfan/version'

Gem::Specification.new do |gem|
  gem.name          = 'ironfan'
  gem.version       = Ironfan::VERSION
  gem.authors       = %w[ Infochimps ]
  gem.email         = 'coders@infochimps.com'
  gem.homepage      = 'http://infochimps.com/labs'
  gem.licenses      = %w[ apachev2 ]
  gem.summary       = "Infochimps' lightweight cloud orchestration toolkit, built on top of Chef."
  gem.description   = <<-DESC.gsub(/^ {4}/, '').chomp
    Ironfan allows you to orchestrate not just systems, but clusters of machines.
    It includes a powerful layer on top of knife and a collection of cloud cookbooks.
  DESC
  gem.files         = `git ls-files`.split($/)
  gem.test_files    = gem.files.grep(/^spec/)
  gem.require_paths = %w[ lib ]
    
  gem.add_dependency('chef',       '10.30.4')
  gem.add_dependency('fog',        '1.21.0')
  gem.add_dependency('unf',        '0.1.3')
  gem.add_dependency('excon',      '0.32.1')
  gem.add_dependency('formatador', '0.2.4')
  gem.add_dependency('gorillib',   '~> 0.6.0')
  gem.add_dependency('rbvmomi',    '1.8.1')
  gem.add_dependency('diff-lcs',   '1.2.5')

  gem.add_development_dependency('bundler', '~> 1.0')

  gem.required_ruby_version = '< 2'
end
