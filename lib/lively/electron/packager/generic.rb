# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "lively"

# @namespace
module Lively
	# @namespace
	module Electron
		# @namespace
		module Packager
			# Raised when {Packager.resolve_electron_executable} cannot produce a usable path from any candidate root, or when a custom {Generic#electron_executable_path} signals failure for every root.
			class NotFoundError < StandardError; end
			
			# A tool-agnostic Node project layout. Both {Npm} and {Pnpm} place CLI shims in `node_modules/.bin` after install. Subclasses implement the concrete {install_command} and {setup!} flows.
			class Generic
				# @attribute [String] Semver range for the `electron` dependency written by {setup!}.
				ELECTRON_VERSION_RANGE = "^41.0.0"
				
				# The `argv` for a top-level install with the current packager (e.g. `pnpm install` or `npm install`).
				# @returns [Array(String)] The program name and arguments, ready for `Process.spawn`.
				# @raises [NotImplementedError] When the concrete packager has not overridden this method.
				# @abstract
				def install_command
					raise NotImplementedError, "#{self.class} must implement #install_command"
				end
				
				# Runs {install_command} inside `package_root` (e.g. from a bake or CI task).
				# @parameter package_root [String] The directory passed as `chdir` to the subprocess.
				# @raises [RuntimeError] If the install command exits with a non-zero status.
				def run_install_in!(package_root)
					args = install_command
					unless system(*args, chdir: File.expand_path(package_root), exception: false)
						raise "Command failed: #{args.join(" ")} (in #{package_root})"
					end
				end
				
				# Creates a `package.json` when none exists using the tool's `init` flow, then adds {ELECTRON_VERSION_RANGE} as a dependency.
				# @parameter package_root [String] The project directory to initialise.
				# @raises [NotImplementedError] When the concrete packager has not overridden this method.
				# @abstract
				def setup!(package_root)
					raise NotImplementedError, "#{self.class} must implement #setup!"
				end
				
				# Resolves a filesystem path to the `electron` binary. A non-empty `ELECTRON` entry in `environment` wins outright; otherwise looks for an executable `node_modules/.bin/electron` shim under `package_root`.
				# @parameter package_root [String] A directory that may contain a local `node_modules`.
				# @parameter environment [Hash] The process environment. Defaults to `::ENV`.
				# @returns [String] The absolute path to the `electron` binary.
				# @raises [NotFoundError] If no usable binary is found under `package_root`.
				def electron_executable_path(package_root, environment = ::ENV)
					explicit = environment["ELECTRON"]&.to_s
					if explicit && !explicit.empty?
						return File.expand_path(explicit)
					end
					
					path = local_electron_path(package_root)
					return path if File.executable?(path)
					
					raise NotFoundError, "Could not find electron in #{package_root}."
				end
				
				# A human-readable suggestion for running the install command in `root`. Useful when `electron` is absent from both `node_modules` and `PATH`.
				# @parameter root [String] The path shown in the hint.
				# @returns [String] A one-line string of the form `Run: ... in <absolute_path>`.
				def install_hint(root)
					"Run: #{install_command.join(' ')} in #{File.expand_path(root)}"
				end
				
				private
				
				# @returns [String] The expanded path to the `node_modules/.bin/electron` shim under `root`.
				def local_electron_path(root)
					root = File.expand_path(root)
					bin = File.join(root, "node_modules", ".bin", "electron")
					if Gem.win_platform? && !File.exist?(bin)
						bin = File.join(root, "node_modules", ".bin", "electron.cmd")
					end
					File.expand_path(bin)
				end
				
				# Runs a subprocess in `package_root` and raises on failure.
				# @parameter argv [Array(String)] The program and its arguments.
				# @parameter package_root [String] Working directory for the command.
				# @parameter label [String] A short description used in failure messages.
				# @raises [RuntimeError] If the process exits with a non-zero status.
				def run_subprocess!(argv, package_root, label)
					root = File.expand_path(package_root)
					unless system(*argv, chdir: root, exception: false)
						raise "Command failed: #{label} – #{argv.join(" ")} (in #{root})"
					end
				end
			end
		end
	end
end
