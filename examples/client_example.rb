#!/usr/bin/env ruby
require 'model_context_protocol'

# Create an MCP client
client = ModelContextProtocol::Client.new(
  { name: "Ruby MCP Client Example", version: "1.0.0" },
  { capabilities: { prompts: {}, resources: {}, tools: {} } }
)

# Connect to a server
transport = ModelContextProtocol::ClientTransports::StdioClientTransport.new(
  command: "ruby",
  args: ["examples/server_example.rb"]
)

begin
  puts "Connecting to the server..."
  client.connect(transport)
  puts "Connected successfully!"

  # List tools
  tools = client.list_tools
  puts "\nAvailable tools: #{tools[:tools].map { |t| t[:name] }.join(', ')}"

  # Call the add tool
  result = client.call_tool({
    name: "add",
    arguments: { a: 5, b: 7 }
  })
  puts "\nAdd tool result: 5 + 7 = #{result[:content][0][:text]}"

  # List resources
  begin
    resources = client.list_resources
    puts "\nAvailable resources: #{resources[:resources].map { |r| r[:name] }.join(', ')}"

    # Read a resource
    if resources[:resources].any? { |r| r[:name] == "greeting" }
      resource = client.read_resource("greeting://World")
      puts "Resource content: #{resource[:contents][0][:text]}"
    end
  rescue => e
    puts "Error accessing resources: #{e.message}"
  end

rescue => e
  puts "Error: #{e.message}"
ensure
  # Disconnect
  client.disconnect
  puts "\nDisconnected from server."
end

