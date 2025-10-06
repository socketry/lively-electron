# frozen_string_literal: true

require_relative "lib/lively/electron/version"

Gem::Specification.new do |spec|
	spec.name = "lively-electron"
	spec.version = Lively::Electron::VERSION
	
	spec.summary = "Electron wrapper for Lively Ruby applications"
	spec.authors = ["Samuel Williams"]
	spec.license = "MIT"
	
	spec.cert_chain  = ["release.cert"]
	spec.signing_key = File.expand_path("~/.gem/release.pem")
	
	spec.homepage = "https://github.com/socketry/lively-electron"
	
	spec.metadata = {
		"documentation_uri" => "https://github.com/socketry/lively-electron/",
		"funding_uri" => "https://github.com/sponsors/ioquatix",
		"source_code_uri" => "https://github.com/socketry/lively-electron.git",
	}
	
	spec.files = Dir.glob(["{context,lib,src}/**/*", "*.md", "*.yaml"], File::FNM_DOTMATCH, base: __dir__)
	
	spec.executables = ["lively-electron-server", "lively-electron"]
	
	spec.required_ruby_version = ">= 3.2"
	
	spec.add_dependency "lively", "~> 0.14"
	
	spec.add_development_dependency "sus"
	spec.add_development_dependency "covered" 
	spec.add_development_dependency "bake-test"
end
