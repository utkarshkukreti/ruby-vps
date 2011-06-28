# encoding: utf-8

Gem::Specification.new do |gem|

  ##
  # General configuration / information
  gem.name        = 'gens'
  gem.version     = '0.0.0'
  gem.platform    = Gem::Platform::RUBY
  gem.authors     = 'Michael van Rooijen'
  gem.email       = 'meskyanichi@gmail.com'
  gem.homepage    = 'http://michaelvanrooijen.com/'
  gem.summary     = %|Gens Summary|
  gem.description = %|Gens Description|

  ##
  # Files and folder that need to be compiled in to the Ruby Gem
  gem.files = %x[git ls-files].split("\n")

  ##
  # The Backup CLI executable
  gem.executables = ['gen-nginx']

  ##
  # Production gem dependencies
  gem.add_dependency 'thor', ['~> 0.14.6']

end
