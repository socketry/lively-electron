# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "lively/electron"
require "sus/fixtures/async"
require "timeout"

describe "lively-electron integration" do
	include Sus::Fixtures::Async
	
	let(:example_path) {File.expand_path("../../../examples/hello-world/application.rb", __dir__)}
	let(:lively_electron_command) {File.expand_path("../../../bin/lively-electron", __dir__)}
	
	it "can start and stop the hello-world example" do
		pid = nil
		
		begin
			# Start the lively-electron application in background
			pid = Process.spawn(
				{"LIVELY_VARIANT" => "development"}, 
				lively_electron_command, example_path,
				chdir: File.dirname(example_path),
			)
			
			# Give it time to start up
			sleep 3
			
			# Verify the process is still running
			expect(Process.kill(0, pid)).to be == 1
		ensure
			if pid
				begin
					Process.kill("TERM", pid)
					Process.waitpid(pid, Process::WNOHANG)
				rescue Errno::ESRCH, Errno::ECHILD
					# Process already gone
				end
			end
		end
	end
	
	it "can start the server component independently" do
		lively_server_command = File.expand_path("../../../bin/lively-electron-server", __dir__)
		
		pid = nil
		
		begin
			# Start just the Ruby server
			pid = Process.spawn(
				lively_server_command, example_path,
				chdir: File.dirname(example_path),
			)
			
			# Give it time to start up
			sleep 3
			
			# Verify the process is still running
			expect(Process.kill(0, pid)).to be == 1
		ensure
			if pid
				begin
					Process.kill("TERM", pid)
					# Wait for clean shutdown
					Timeout.timeout(5) do
						Process.waitpid(pid)
					end
				rescue Errno::ESRCH, Errno::ECHILD
					# Process already gone
				rescue Timeout::Error
					# Force kill if it won't terminate cleanly
					Process.kill("KILL", pid) rescue nil
				end
			end
		end
	end
end
