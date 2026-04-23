# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require_relative "generic"

# @namespace
module Lively
	# @namespace
	module Electron
		# @namespace
		module Packager
			# An npm (`package-lock.json`) project layout with the corresponding `npm` command line.
			class Npm < Generic
				# @returns [String] The user-visible packager name, `"npm"`, used in messages and hints.
				def to_s = "npm"
				
				# @returns [Array(String)] `["npm", "install"]` for a full dependency install.
				def install_command
					%w[npm install]
				end
				
				# Creates a `package.json` and installs {ELECTRON_VERSION_RANGE} when no manifest exists yet; see {Generic#setup!}.
				# @parameter package_root [String] The project directory.
				# @raises [RuntimeError] If any subprocess step fails.
				def setup!(package_root)
					manifest = File.join(File.expand_path(package_root), "package.json")
					return if File.file?(manifest)
					
					run_subprocess!(%w[npm init -y], package_root, "npm init -y")
					run_subprocess!(
						[
							"npm", "install", "--save-prod",
							"electron@#{ELECTRON_VERSION_RANGE}"
						],
						package_root,
						"npm install electron"
					)
				end
			end
		end
	end
end
