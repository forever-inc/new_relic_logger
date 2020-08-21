require_relative 'lib/new_relic_logger/version'

Gem::Specification.new do |spec|
  spec.name          = "new_relic_logger"
  spec.version       = NewRelicLogger::VERSION
  spec.authors       = ["Chris Ryan"]
  spec.email         = ["cryan@forever.com"]

  spec.summary               = 'Some summary'
  spec.description           = 'Some description'
  spec.homepage              = 'https://www.forever.com'
  spec.license               = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = 'https://www.forever.com'
  spec.metadata["changelog_uri"]   = 'https://www.forever.com'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.add_dependency 'newrelic_rpm'

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
