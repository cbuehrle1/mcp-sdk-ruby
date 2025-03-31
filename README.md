# README.md
# Model Context Protocol Ruby SDK

This is a Ruby implementation of the [Model Context Protocol](https://spec.modelcontextprotocol.io/), a standard for connecting AI models with external resources and tools.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'model_context_protocol'
```

And then execute:

```
$ bundle install
```

Or install it yourself as:

```
$ gem install model_context_protocol
```

## Usage

### Creating an MCP Server

```ruby
require 'model_context_protocol'

# Create an MCP server
server = ModelContextProtocol::Server::McpServer.new({
  name: "Demo",
  version: "1.0.0"
})

# Add a simple addition tool
server.tool("add", {
  a: { type: "integer" },
  b: { type: "integer" }
}) do |params|
  {
    content: [
      { type: "text", text: (params["a"] + params["b"]).to_s }
    ]
  }
end

# Add a dynamic greeting resource
server.resource(
  "greeting",
  ModelContextProtocol::Server::ResourceTemplate.new("greeting://{name}", { list: nil }),
  lambda do |uri, params|
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
)

# Start receiving messages on stdin and sending messages on stdout
transport = ModelContextProtocol::Server::StdioServerTransport.new
server.connect(transport)

# Keep the process running
begin
  sleep
rescue Interrupt
  # Handle Ctrl+C
end
```

### Creating an MCP Client

```ruby
require 'model_context_protocol'

# Create an MCP client
client = ModelContextProtocol::Client.new(
  { name: "example-client", version: "1.0.0" },
  { capabilities: { prompts: {}, resources: {}, tools: {} } }
)

# Connect to a server
transport = ModelContextProtocol::Client::StdioClientTransport.new(
  command: "ruby",
  args: ["server.rb"]
)
client.connect(transport)

# List resources
resources = client.list_resources
puts "Available resources: #{resources[:resources].map { |r| r[:name] }.join(', ')}"

# Read a resource
resource = client.read_resource("greeting://World")
puts "Resource content: #{resource[:contents][0][:text]}"

# Call a tool
result = client.call_tool({
  name: "add",
  arguments: { a: 5, b: 7 }
})
puts "Tool result: #{result[:content][0][:text]}"

# Disconnect
client.disconnect
```

## PostgreSQL Integration

The gem includes support for PostgreSQL databases, allowing you to expose database schemas and run read-only queries:

```ruby
require 'model_context_protocol'
require 'pg'

# Create an MCP server for PostgreSQL
server = ModelContextProtocol::Server::McpServer.new({
  name: "PostgreSQL MCP",
  version: "1.0.0"
})

# Connect to PostgreSQL
conn = PG.connect("postgres://username:password@localhost:5432/database")

# Add a query tool
server.tool("query", {
  sql: { type: "string" }
}) do |params|
  begin
    conn.exec("BEGIN TRANSACTION READ ONLY")
    result = conn.exec(params["sql"])
    
    {
      content: [
        { type: "text", text: JSON.generate(result.to_a) }
      ]
    }
  ensure
    conn.exec("ROLLBACK")
  end
end

# Start the server
transport = ModelContextProtocol::Server::StdioServerTransport.new
server.connect(transport)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yourusername/model_context_protocol_rb.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
