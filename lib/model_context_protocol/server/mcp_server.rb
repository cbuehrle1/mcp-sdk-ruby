# lib/model_context_protocol/server/mcp_server.rb
require 'concurrent'
require 'json'
require_relative 'resource_template'

module ModelContextProtocol
  module Server
    class McpServer
      attr_reader :server_info, :tools, :resources, :prompts

      def initialize(server_info)
        @server_info = server_info
        @server = BaseServer.new(server_info, {
          capabilities: {
            resources: {},
            tools: {},
            prompts: {}
          }
        })

        @tools = {}
        @resources = {}
        @prompts = {}

        # Register standard handlers
        register_standard_handlers
      end

      def connect(transport)
        @server.connect(transport)
      end

      def tool(name, schema, &handler)
        @tools[name] = {
          name: name,
          input_schema: schema,
          handler: handler
        }
      end

      def resource(name, template, &handler)
        @resources[name] = {
          name: name,
          template: template,
          handler: handler
        }
      end

      def prompt(name, schema, &handler)
        @prompts[name] = {
          name: name,
          input_schema: schema,
          handler: handler
        }
      end

      def override_request_handler(name, &handler)
        @server.set_request_handler(name, &handler)
      end

      private

      def register_standard_handlers
        # Initialize server

        # List resources
        @server.set_request_handler("resources/list") do |params|
          resources = @resources.values.map do |resource|
            {
              template: resource[:template].to_h[:template],
              capabilities: resource[:template].to_h[:capabilities],
              name: resource[:name]
            }
          end

          { resources: resources }
        end

        # Read resource
        @server.set_request_handler("resources/read") do |params|
          uri = params[:uri]

          # Find matching resource
          resource_entry = nil
          parameters = nil

          @resources.each_value do |resource|
            params_match = resource[:template].match(uri)
            if params_match
              resource_entry = resource
              parameters = params_match
              break
            end
          end

          if resource_entry.nil?
            raise StandardError, "Resource not found: #{uri}"
          end

          # Call handler
          result = resource_entry[:handler].call(URI(uri), parameters)

          # Validate result
          unless result.is_a?(Hash) && result[:contents].is_a?(Array)
            raise StandardError, "Resource handler must return { contents: [...] }"
          end

          result
        end

        # List tools
        @server.set_request_handler("tools/list") do |params|
          tools = @tools.values.map do |tool|
            {
              name: tool[:name],
              inputSchema: tool[:input_schema]
            }
          end

          { tools: tools }
        end

        # Call tool
        @server.set_request_handler("tools/call") do |params|
          name = params[:name]
          arguments = params[:arguments] || {}

          tool = @tools[name]
          if tool.nil?
            raise StandardError, "Tool not found: #{name}"
          end

          # Call handler
          result = tool[:handler].call(arguments)

          # Validate result
          unless result.is_a?(Hash) && result[:content].is_a?(Array)
            raise StandardError, "Tool handler must return { content: [...] }"
          end

          result[:is_error] = !!result[:is_error]
          result
        end

        # List prompts
        @server.set_request_handler("prompts/list") do |params|
          prompts = @prompts.values.map do |prompt|
            {
              name: prompt[:name],
              inputSchema: prompt[:input_schema]
            }
          end

          { prompts: prompts }
        end

        # Get prompt
        @server.set_request_handler("prompts/get") do |params|
          name = params[:name]
          arguments = params[:arguments] || {}

          prompt = @prompts[name]
          if prompt.nil?
            raise StandardError, "Prompt not found: #{name}"
          end

          # Call handler
          result = prompt[:handler].call(arguments)

          # Validate result
          unless result.is_a?(Hash) && result[:messages].is_a?(Array)
            raise StandardError, "Prompt handler must return { messages: [...] }"
          end

          result
        end
      end
    end
  end
end
