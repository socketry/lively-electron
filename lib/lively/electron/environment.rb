# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "lively/environment/application"
require "io/endpoint/bound_endpoint"
require "console"

# @namespace
module Lively
	# @namespace
	module Electron
		# @namespace
		module Environment
			# The Lively environment for a desktop Electron shell that connects to this process over a local HTTP server.
			# The server uses TCP and may inherit a bound socket passed via `LIVELY_SERVER_DESCRIPTOR`.
			module Application
				include Lively::Environment::Application
				
				# The base URL the Electron shell uses to reach the Lively server.
				# Reads `LIVELY_URL` from the environment, or defaults to `http://localhost:0/`.
				# @returns [String]
				def url
					ENV.fetch("LIVELY_URL", "http://localhost:0/")
				end
				
				# The HTTP endpoint the server listens on.
				# When `LIVELY_SERVER_DESCRIPTOR` is set, reuses the inherited bound socket instead of binding a new one.
				# @returns [Async::HTTP::Endpoint]
				def endpoint
					if descriptor = ENV["LIVELY_SERVER_DESCRIPTOR"]
						Console.info(self, "Using inherited file descriptor.", descriptor: descriptor)
						bound_socket = Socket.for_fd(descriptor.to_i)
						
						# Ensure the inherited socket is non-blocking:
						bound_socket.nonblock = true
						
						endpoint = IO::Endpoint::BoundEndpoint.new(nil, [bound_socket])
					end
					
					Async::HTTP::Endpoint.parse(self.url, endpoint)
				end
			end
		end
	end
end
