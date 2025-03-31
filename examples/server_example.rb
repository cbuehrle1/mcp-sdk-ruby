#!/usr/bin/env ruby
require 'model_context_protocol'

# Create an MCP server
server = ModelContextProtocol::Server::McpServer.new({
  name: "Ruby MCP Example",
  version: "1.0.0"
})

# Add a simple addition tool
server.tool("add", { a: { type: "integer" }, b: { type: "integer" }}) { |params| { content: [{ type: "text", text: (params[:a] + params[:b]).to_s }]}  }

# Add a dynamic greeting resource
server.resource("greeting", ModelContextProtocol::Server::ResourceTemplate.new("greeting://{name}", { list: nil })) do |uri, params|
  {
    contents: [
      {
        uri: uri.to_s,
        mimeType: "text/plain",
        text: "Hello, #{params["name"]}!"
      }
    ]
  }
end

# Start receiving messages on stdin and sending messages on stdout
transport = ModelContextProtocol::Server::StdioServerTransport.new
server.connect(transport)

# Keep the process running
begin
  sleep
rescue Interrupt
  # Handle Ctrl+C
end
