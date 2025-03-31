#!/usr/bin/env ruby
require 'model_context_protocol'
require 'pg'

# This example mirrors the TypeScript PostgreSQL server from the original code

if ARGV.length == 0
  puts "Please provide a database URL as a command-line argument"
  exit 1
end

database_url = ARGV[0]
resource_base_url = URI.parse(database_url)
resource_base_url.scheme = "postgres"
resource_base_url.password = ""

# Create connection pool
conn = PG.connect(database_url)
SCHEMA_PATH = "schema"

# Create an MCP server
server = ModelContextProtocol::Server::McpServer.new({
  name: "Ruby PostgreSQL MCP Example",
  version: "0.1.0"
})

# List resources handler
server.tool("list_resources", {}) do |params|
  begin
    result = conn.exec("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'")
    resources = result.map do |row|
      table_name = row["table_name"]
      uri = "#{resource_base_url}/#{table_name}/#{SCHEMA_PATH}"
      {
        uri: uri,
        mimeType: "application/json",
        name: "\"#{table_name}\" database schema"
      }
    end

    {
      content: [
        { type: "text", text: JSON.generate({ resources: resources }) }
      ]
    }
  rescue => e
    {
      content: [
        { type: "text", text: "Error: #{e.message}" }
      ],
      is_error: true
    }
  end
end

# Read resource handler
server.tool("read_resource", {
  uri: { type: "string" }
}) do |params|
  begin
    resource_url = URI.parse(params["uri"])
    path_components = resource_url.path.split('/')
    schema = path_components.pop
    table_name = path_components.pop

    if schema != SCHEMA_PATH
      raise "Invalid resource URI"
    end

    result = conn.exec_params(
      "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = $1",
      [table_name]
    )

    {
      content: [
        {
          type: "text",
          text: JSON.generate({
            contents: [
              {
                uri: params["uri"],
                mimeType: "application/json",
                text: JSON.generate(result.to_a)
              }
            ]
          })
        }
      ]
    }
  rescue => e
    {
      content: [
        { type: "text", text: "Error: #{e.message}" }
      ],
      is_error: true
    }
  end
end

# Query tool
server.tool("query", {
  sql: { type: "string" }
}) do |params|
  begin
    sql = params["sql"]
    conn.exec("BEGIN TRANSACTION READ ONLY")
    result = conn.exec(sql)

    {
      content: [
        { type: "text", text: JSON.generate(result.to_a) }
      ]
    }
  rescue => e
    {
      content: [
        { type: "text", text: "Error: #{e.message}" }
      ],
      is_error: true
    }
  ensure
    begin
      conn.exec("ROLLBACK")
    rescue => e
      puts "Could not roll back transaction: #{e.message}"
    end
  end
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

