# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "executable_pathname/version"

Gem::Specification.new do |spec|
  spec.name          = "executable_pathname"
  spec.version       = ExecutablePathname::VERSION
  spec.authors       = ["Alan Stebbens"]
  spec.email         = ["aks@stebbens.org"]

  spec.summary       = %q{Additional methods for inspecting executable pathnames as subclass to Pathname}
  spec.description   = %q{Provide additional methods to inspect executable files, as a Pathname subclass}
  spec.homepage      = "https://github.com/aks/executable_pathname"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.6.0"
  spec.add_development_dependency "activesupport", "~> 5.1.3"
  spec.add_development_dependency "fuubar", "~> 2.2.0"
  spec.add_development_dependency "pry-byebug", "~> 3.5.0"
end
