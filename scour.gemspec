require_relative 'lib/scour/version'

Gem::Specification.new do |spec|
  spec.required_ruby_version = '~> 3.0'

  spec.name        = 'scour'
  spec.version     = Scour::VERSION
  spec.authors     = ['Mylan Connolly']
  spec.email       = ['mylan@mylan.io']
  spec.homepage    = 'https://github.com/mylanconnolly/scour'
  spec.summary     = 'A search library for Rails'
  spec.description = 'A search library for Rails'
  spec.license     = 'MIT'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']
  end

  spec.add_dependency 'rails', '>= 7.0.7.1'
end
