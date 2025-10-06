#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "lively"

class HelloWorldView < Live::View
	def initialize(...)
		super
		
		@data[:message] ||= "Hello from Lively Electron!"
	end
	
	def count
		@data[:count].to_i
	end
	
	def count=(value)
		@data[:count] = value.to_s
	end
	
	def handle(event)
		action = event[:detail][:action]
		case action
		when "click"
			self.count += 1
			@data[:message] = "Clicked #{@data[:count]} times!"
			update!
		when "reset"
			self.count = 0
			@data[:message] = "Click the button below."
			update!
		end
	end
	
	def render(builder)
		builder.tag(:div, class: "hello-app") do
			builder.tag(:h1) {builder.text(@data[:message])}
			
			builder.tag(:div, class: "buttons") do
				builder.tag(:button, onClick: forward_event(action: "click")) do
					builder.text("Click me!")
				end
				
				if self.count > 0
					builder.tag(:button, onClick: forward_event(action: "reset"), class: "reset") do
						builder.text("Reset")
					end
				end
			end
			
			builder.tag(:p, class: "info") do
				builder.text("This Lively app is running in Electron via file descriptor inheritance")
			end
			
			builder.tag(:p, class: "tech") do
				builder.text("Node.js (bind port) → FD inheritance → Ruby (Lively) ↔ HTTP ↔ Electron (Chromium)")
			end
		end
	end
end

Application = Lively::Application[HelloWorldView]
