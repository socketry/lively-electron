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
			# Represents the environment configuration for a Lively Electron application server.
			# 
			# This module provides server configuration for Electron apps, using TCP
			# localhost binding for direct connection from Electron/Chromium.
			module Application
				include Lively::Environment::Application
				
				def url
					"http://localhost:0/"
				end
				
				def endpoint
					if descriptor = ENV["LIVELY_SERVER_DESCRIPTOR"]
						Console.info(self, "Using inherited file descriptor.", descriptor: descriptor)
						bound_socket = Socket.for_fd(descriptor.to_i)
						
						# Ensure that the socket is non-blocking:
						bound_socket.nonblock = true
						
						endpoint = IO::Endpoint::BoundEndpoint.new(nil, [bound_socket])
					end
					
					Async::HTTP::Endpoint.parse(self.url, endpoint)
				end
			end
		end
	end
end
