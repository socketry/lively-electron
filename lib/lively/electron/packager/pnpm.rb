# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "json"
require_relative "generic"

# @namespace
module Lively
	# @namespace
	module Electron
		# @namespace
		module Packager
			# A pnpm (`pnpm-lock.yaml`) project layout with the corresponding `pnpm` command line.
			class Pnpm < Generic
				# @returns [String] The user-visible packager name, `"pnpm"`, used in messages and hints.
				def to_s = "pnpm"
				
				# @returns [Array(String)] `["pnpm", "install"]` for a full dependency install.
				def install_command
					%w[pnpm install]
				end
				
				# Creates a `package.json` and installs {ELECTRON_VERSION_RANGE} when no manifest exists yet; see {Generic#setup!}. Also writes the `onlyBuiltDependencies` policy required by pnpm 10+.
				# @parameter package_root [String] The project directory.
				# @raises [RuntimeError] If any subprocess step fails.
				def setup!(package_root)
					manifest = File.join(File.expand_path(package_root), "package.json")
					return if File.file?(manifest)
					
					# pnpm 10 requires --bare and --init-package-manager (see `pnpm help init`):
					run_subprocess!(%w[pnpm init --bare --init-package-manager], package_root, "pnpm init")
					run_subprocess!(
						[
							"pnpm", "add",
							"electron@#{ELECTRON_VERSION_RANGE}"
						],
						package_root,
						"pnpm add electron"
					)
					merge_electron_postinstall_policy!(package_root)
				end
				
				private
				
				# Ensures `electron` is listed under `pnpm.onlyBuiltDependencies` in `package.json`. Without this entry, pnpm 10+ blocks `electron`'s `postinstall` script.
				# @parameter package_root [String] The project directory containing `package.json`.
				def merge_electron_postinstall_policy!(package_root)
					path = File.join(File.expand_path(package_root), "package.json")
					data = JSON.parse(File.read(path, encoding: Encoding::UTF_8))
					pnode = data["pnpm"] || {}
					list = pnode["onlyBuiltDependencies"] || []
					pnode["onlyBuiltDependencies"] = (["electron"] + Array(list)).uniq
					data["pnpm"] = pnode
					File.write(path, JSON.pretty_generate(data) + "\n")
				end
			end
		end
	end
end
