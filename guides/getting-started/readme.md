# Getting Started

This guide explains how to get started with `lively-electron` to create desktop applications from Lively Ruby applications.

## Installation

Add the gem to your project:

~~~ bash
$ bundle add lively-electron
~~~

Also install the npm package for the Electron wrapper:

~~~ bash
$ npm install lively-electron
~~~

## Core Concepts

`lively-electron` has several core components:

- A {ruby Lively::Electron::Environment::Application} which provides the server configuration for Electron apps using file descriptor inheritance.
- Standard {ruby Lively::Application} classes work without modification in desktop applications.

## Usage

Create a new directory for your desktop app:

~~~ bash
$ mkdir my_desktop_app
$ cd my_desktop_app
~~~

Create a `gems.rb` file:

~~~ ruby
source "https://rubygems.org"

gem "lively-electron"
~~~

Install the dependencies:

~~~ bash
$ bundle install
~~~

### Creating Your Application

Create an `application.rb` file:

~~~ ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

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
			builder.tag(:h1) { builder.text(@data[:message]) }
			
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
~~~

### Styling Your Application

Create a `public/_static/index.css` file:

~~~ css
body {
	margin: 0;
	font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
	background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
	min-height: 100vh;
	display: flex;
	align-items: center;
	justify-content: center;
}

.hello-app {
	background: white;
	border-radius: 12px;
	padding: 40px;
	box-shadow: 0 10px 30px rgba(0,0,0,0.2);
	text-align: center;
	max-width: 500px;
	margin: 20px;
}

.hello-app h1 {
	color: #333;
	margin-bottom: 30px;
	font-size: 2.2em;
	font-weight: 300;
}

.buttons {
	margin: 30px 0;
}

.buttons button {
	background: #007acc;
	color: white;
	border: none;
	padding: 14px 28px;
	border-radius: 8px;
	font-size: 16px;
	cursor: pointer;
	margin: 0 10px;
	transition: all 0.2s ease;
}

.buttons button:hover {
	background: #005a9e;
	transform: translateY(-1px);
}

.buttons button.reset {
	background: #dc3545;
}

.buttons button.reset:hover {
	background: #c82333;
}

.info {
	color: #666;
	margin: 30px 0 10px;
	font-size: 1.1em;
}

.tech {
	color: #999;
	font-size: 0.9em;
	font-family: Monaco, 'Courier New', monospace;
	background: #f8f9fa;
	padding: 10px;
	border-radius: 4px;
	margin-top: 20px;
}
~~~

### Running Your Desktop App

Launch your Lively application in Electron:

~~~ bash
$ lively-electron application.rb
~~~

You should see a desktop window with your interactive Lively application running natively.

### Development Mode

For development with DevTools enabled:

~~~ bash
$ lively-electron --development application.rb
~~~

### Testing Server Only

You can test just the Ruby server component:

~~~ bash
$ lively-electron-server application.rb
~~~

This starts the server without opening the Electron window, useful for debugging the Ruby application logic.
