
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "cacheql/version"

Gem::Specification.new do |spec|
  spec.name          = "cacheql"
  spec.version       = CacheQL::VERSION
  spec.authors       = ["Nick Quaranto"]
  spec.email         = ["nick@quaran.to"]

  spec.summary       = %q{Various GraphQL caching / instrumentation tools}
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/chatterbugapp/cacheql"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "graphql-batch", "~> 0.4"

  spec.add_development_dependency "activesupport"
  spec.add_development_dependency "activerecord"
  spec.add_development_dependency "railties"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
end
