require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/{gorillib,ironfan,chef,ironfan/*}/*_spec.rb'
end

desc 'Run RSpec code examples with SimpleCov'
task :coverage do
  ENV['IRONFAN_COV'] = 'true'
  Rake::Task[:spec].invoke
end

desc 'Run RSpec integration code examples'
RSpec::Core::RakeTask.new(:integration) do |spec|
  spec.pattern = 'spec/integration/**/*_spec.rb'
end

require 'yard'
YARD::Rake::YardocTask.new do |t|
  additional_docs = %w[ CHANGELOG.md LICENSE.md README.md notes/INSTALL.md
                        notes/core_concepts.md notes/knife-cluster-commands.md
                        notes/philosophy.md notes/silverware.md notes/style_guide.md
                        notes/tips_and_troubleshooting.md notes/walkthrough-hadoop.md
                        notes/homebase-layout.txt notes/*.md notes/*.txt ]
  t.files   = ['lib/**/*.rb', '-'] + additional_docs
  t.options = ['--readme=README.md', '--markup=markdown', '--verbose']
end

desc 'Generate YARD Documentation'
task doc: [:yard]

task default: [:spec]
