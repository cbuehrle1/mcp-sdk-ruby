require 'concurrent'
require 'json'

module ModelContextProtocol
  class BaseServer
    attr_reader :server_info, :capabilities, :request_handlers

    def initialize(server_info, options = {})
      @server_info = server_info
      @capabilities = options[:capabilities] || {
        resources: {},
        tools: {},
        prompts: {}
      }
      @request_handlers = {}
      @connected = false

      # Register default hello handler
      set_request_handler("initialize") do |params|
        {
          "serverInfo" => @server_info,
          "capabilities" => @capabilities,
          "protocolVersion" => "2024-11-05"
        }
      end
    end

    def connect(transport)
      @transport = transport
      @transport.on_message do |message|
        handle_message(message)
      end
      @transport.connect
      @connected = true
    end

    def disconnect
      return unless @connected
      @transport.disconnect
      @connected = false
    end

    def set_request_handler(method, &handler)
      @request_handlers[method] = handler
    end

    private

    def handle_message(message)
      begin
        request = JSON.parse(message, symbolize_names: true)

        # Validate request structure
        unless request[:method].is_a?(String)
          send_error(request[:id], -32600, "Invalid request: method must be a string")
          return
        end

        # Find handler
        handler = @request_handlers[request[:method]]
        if handler.nil?
          send_error(request[:id], -32601, "Method not found: #{request[:method]}")
          return
        end

        # Execute handler
        begin
          result = handler.call(request[:params] || {})
          send_result(request[:id], result)
        rescue => e
          send_error(request[:id], -32000, "Server error: #{e.message}")
        end
      rescue JSON::ParserError => e
        send_error(nil, -32700, "Parse error: #{e.message}")
      end
    end

    def send_result(id, result)
      return unless id

      response = {
        id: id,
        jsonrpc: "2.0",
        result: result
      }

      @transport.send_message(response.to_json)
    end

    def send_error(id, code, message, data = nil)
      return unless id

      error = {
        code: code,
        message: message
      }
      error[:data] = data if data

      response = {
        id: id,
        jsonrpc: "2.0",
        error: error
      }

      @transport.send_message(response.to_json)
    end
  end
end

