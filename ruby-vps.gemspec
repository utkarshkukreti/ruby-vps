# encoding: utf-8

Gem::Specification.new do |gem|

  ##
  # General configuration / information
  gem.name        = 'ruby-vps'
  gem.version     = '0.0.0'
  gem.platform    = Gem::Platform::RUBY
  gem.authors     = 'Michael van Rooijen'
  gem.email       = 'meskyanichi@gmail.com'
  gem.homepage    = 'http://michaelvanrooijen.com/'
  gem.summary     = %|Ruby VPS Summary|
  gem.description = %|Ruby VPS Description|

  ##
  # Files and folder that need to be compiled in to the Ruby Gem
  gem.files = %x[git ls-files].split("\n")

  ##
  # Add the lib dir to the require path
  gem.require_path = 'lib'

  ##
  # The Backup CLI executable
  gem.executables = %w[nginx capistrano mongodb postgresql server].map { |u| "ruby-vps-#{u}" }

  ##
  # Production gem dependencies
  gem.add_dependency 'thor',       ['~> 0.14.6']
  gem.add_dependency 'capistrano', ['~> 2.8.0']
  gem.add_dependency 'net-ssh',    ['~> 2.2.1']
  gem.add_dependency 'net-sftp',   ['~> 2.0.5']

end
