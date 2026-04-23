# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "json"

require_relative "packager/generic"
require_relative "packager/npm"
require_relative "packager/pnpm"

# @namespace
module Lively
	# @namespace
	module Electron
		# Detects the Node packager in use (npm or pnpm) and resolves the `electron` binary path. Both tools place CLI shims in `node_modules/.bin` after install; see {Generic#electron_executable_path}.
		module Packager
			# @attribute [String] Environment variable for explicitly selecting `npm` or `pnpm`.
			ENV_KEY = "LIVELY_ELECTRON_PACKAGER"
			
			class << self
				# Picks a packager for a project root.
				#
				# Resolution order:
				# 1. `LIVELY_ELECTRON_PACKAGER` env var with value `npm` or `pnpm` (case-insensitive);
				# 2. `package.json` `packageManager` field (e.g. `pnpm@10.0.0` or `npm@10.0.0`);
				# 3. a lone lock file (`pnpm-lock.yaml` or `package-lock.json`);
				# 4. if both lock files are present, `pnpm` (matches this gem's default);
				# 5. if there is no clear signal, `pnpm`.
				#
				# @parameter package_root [String] The directory to search for `package.json` and lock files.
				# @parameter environment [Hash] The process environment. Defaults to `::ENV`.
				# @returns [Lively::Electron::Packager::Npm | Lively::Electron::Packager::Pnpm] A concrete {Npm} or {Pnpm} instance.
				# @raises [ArgumentError] If `LIVELY_ELECTRON_PACKAGER` is set to something other than `npm` or `pnpm`.
				def detect(package_root, environment = ::ENV)
					root = File.expand_path(package_root)
					
					if (resolved = from_environment(environment[ENV_KEY]))
						return resolved
					end
					
					if (resolved = from_package_json(root))
						return resolved
					end
					
					has_pnpm = File.file?(File.join(root, "pnpm-lock.yaml"))
					has_npm = File.file?(File.join(root, "package-lock.json"))
					
					if has_pnpm && has_npm
						return Pnpm.new
					elsif has_pnpm
						return Pnpm.new
					elsif has_npm
						return Npm.new
					else
						return Pnpm.new
					end
				end
				
			# Calls {Generic#electron_executable_path} for each of `search_roots` in order (e.g. the app's working directory, then the gem root in development). The first concrete path wins. If no root yields a local binary, falls back to the bare program name `"electron"` for the OS to find on `PATH`.
			# @parameter packager [Lively::Electron::Packager::Generic] A concrete {Npm} or {Pnpm} instance.
			# @parameter search_roots [Array(String)] Candidate directories; first match wins.
			# @parameter environment [Hash] The process environment. Defaults to `::ENV`.
			# @returns [String] An absolute path, or `"electron"` to resolve via `PATH`.
			def resolve_electron_executable(packager, search_roots, environment = ::ENV)
				search_roots
					.compact
					.map { |path| File.expand_path(path) }
					.uniq
					.each do |search_root|
						begin
							return packager.electron_executable_path(search_root, environment)
						rescue NotFoundError
							next
						end
					end
				
				# No local binary found in any root; rely on the OS to find `electron` on PATH:
				"electron"
			end
				
				private
				
				def from_environment(value)
					value = value&.to_s&.strip
					return nil if value.nil? || value.empty?
					
					case value.downcase
					when "npm" then Npm.new
					when "pnpm" then Pnpm.new
					else
						raise ArgumentError, "Invalid #{ENV_KEY} #{value.inspect} (use 'npm' or 'pnpm')."
					end
				end
				
				def from_package_json(root)
					package_json = read_package_json(root) or return nil
					package_manager = package_json["packageManager"].to_s
					return Pnpm.new if package_manager.start_with?("pnpm@")
					return Npm.new if package_manager.start_with?("npm@")
					
					nil
				end
				
				def read_package_json(root)
					path = File.join(root, "package.json")
					return nil unless File.readable?(path)
					
					::JSON.parse(File.read(path, encoding: Encoding::UTF_8))
				rescue ::JSON::ParserError
					nil
				end
			end
		end
	end
end
