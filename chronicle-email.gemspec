
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "chronicle/email/version"

Gem::Specification.new do |spec|
  spec.name          = "chronicle-email"
  spec.version       = Chronicle::Email::VERSION
  spec.authors       = ["Andrew Louis"]
  spec.email         = ["andrew@hyfen.net"]

  spec.summary       = "Email importer for Chronicle"
  spec.description   = "Various email importers for chronicle-etl"
  spec.homepage      = "https://github.com/chronicle-app/chronicle-email"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://github.com/chronicle-app/chronicle-email"
    spec.metadata["changelog_uri"] = "https://github.com/chronicle-app/chronicle-email"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "chronicle-etl", "~> 0.4.4"
  spec.add_dependency "mail", "~> 2.7"
  spec.add_dependency 'email_reply_parser', '~> 0.5'
  spec.add_dependency 'reverse_markdown', '~> 2.0'

  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.9"
end
