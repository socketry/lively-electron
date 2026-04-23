# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "lively/electron/packager"
require "json"
require "tmpdir"

describe Lively::Electron::Packager do
	let(:env) {{}.dup}
	
	def write_json(root, data)
		File.write(File.join(root, "package.json"), JSON.pretty_generate(data))
	end
	
	it "uses LIVELY_ELECTRON_PACKAGER override" do
		tmp = Dir.mktmpdir
		e = { "LIVELY_ELECTRON_PACKAGER" => "npm" }
		expect(Lively::Electron::Packager.detect(tmp, e)).to be_a(Lively::Electron::Packager::Npm)
		e2 = { "LIVELY_ELECTRON_PACKAGER" => "pnpm" }
		expect(Lively::Electron::Packager.detect(tmp, e2)).to be_a(Lively::Electron::Packager::Pnpm)
	end
	
	it "prefers pnpm from packageManager when present" do
		tmp = Dir.mktmpdir
		write_json(tmp, { "packageManager" => "pnpm@9.0.0" })
		expect(Lively::Electron::Packager.detect(tmp, env)).to be_a(Lively::Electron::Packager::Pnpm)
	end
	
	it "prefers npm from packageManager when present" do
		tmp = Dir.mktmpdir
		write_json(tmp, { "packageManager" => "npm@10.0.0" })
		expect(Lively::Electron::Packager.detect(tmp, env)).to be_a(Lively::Electron::Packager::Npm)
	end
	
	it "picks pnpm for pnpm-lock only" do
		tmp = Dir.mktmpdir
		File.write(File.join(tmp, "pnpm-lock.yaml"), "lockfileVersion: '9.0'\n")
		expect(Lively::Electron::Packager.detect(tmp, env)).to be_a(Lively::Electron::Packager::Pnpm)
	end
	
	it "picks npm for package-lock only" do
		tmp = Dir.mktmpdir
		File.write(File.join(tmp, "package-lock.json"), %({"lockfileVersion":1}))
		expect(Lively::Electron::Packager.detect(tmp, env)).to be_a(Lively::Electron::Packager::Npm)
	end
	
	it "picks pnpm when both lock files are present" do
		tmp = Dir.mktmpdir
		File.write(File.join(tmp, "pnpm-lock.yaml"), "lockfileVersion: '9.0'\n")
		File.write(File.join(tmp, "package-lock.json"), %({"lockfileVersion":1}))
		expect(Lively::Electron::Packager.detect(tmp, env)).to be_a(Lively::Electron::Packager::Pnpm)
	end
	
	it "defaults to pnpm when there is no signal" do
		tmp = Dir.mktmpdir
		expect(Lively::Electron::Packager.detect(tmp, env)).to be_a(Lively::Electron::Packager::Pnpm)
	end
	
	it "rejects an invalid LIVELY_ELECTRON_PACKAGER" do
		tmp = Dir.mktmpdir
		e = { "LIVELY_ELECTRON_PACKAGER" => "yarn" }
		expect do
			Lively::Electron::Packager.detect(tmp, e)
		end.to raise_exception(ArgumentError)
	end
end
