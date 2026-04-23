# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

# Creates +package.json+ in the project root with +pnpm init+ or +npm init+ when it is
# missing, then runs the appropriate install command for {Lively::Electron::Packager}.
def install
	require "console"
	require "lively/electron/packager"
	
	root = context.root
	package_json_path = File.join(root, "package.json")
	packager = Lively::Electron::Packager.detect(root, ::ENV)
	
	unless File.file?(package_json_path)
		packager.setup!(root)
		Console.info(self, "Created", package_json_path, "using", packager)
	end
	
	packager.run_install_in!(root)
end
