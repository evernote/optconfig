# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'optconfig/version'

Gem::Specification.new do |spec|
    spec.name          = "noms-optconfig"
    spec.version       = Optconfig::VERSION
    spec.authors       = ["Jeremy Brinkley"]
    spec.email         = ["jbrinkley@evernote.com"]
    spec.summary       = %q{Parse commmand-line options and config files}
    spec.description   = %q{Optconfig presents a standardized way to parse configuration files and command-line arguments}
    spec.homepage      = "http://github.com/evernote/optconfig"
    spec.license       = "Apache-2"

    spec.files         = ['lib/optconfig.rb', 'lib/optconfig/version.rb',
        'lib/longopt.rb', 'lib/bashon.rb', 'bin/ruby-showconfig',
        'bin/optconfig.sh', 'bin/bash-showconfig']

    spec.executables   = ['ruby-showconfig']
    spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
    spec.require_paths = ["lib"]

    spec.add_development_dependency "bundler", "~> 1.7"
    spec.add_development_dependency "rake", "~> 10.0"
    spec.add_development_dependency "rspec", "~> 2.11"
end
