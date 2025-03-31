# lib/model_context_protocol/client/base_client.rb
require 'concurrent'
require 'securerandom'
require 'json'

module ModelContextProtocol
  class Client
    attr_reader :client_info, :capabilities

    def initialize(client_info, capabilities)
      @client_info = client_info
      @capabilities = capabilities
      @pending_requests = Concurrent::Map.new
      @connected = false
    end

    def connect(transport)
      @transport = transport
      @transport.on_message do |message|
        handle_message(message)
      end
      @transport.connect

      hello_response = request({
        method: "hello",
        params: {
          client: @client_info,
          capabilities: @capabilities
        }
      })

      @connected = true
      @server_info = hello_response[:server]
      @server_capabilities = hello_response[:capabilities]

      true
    end

    def disconnect
      return unless @connected
      @transport.disconnect
      @connected = false
    end

    def list_resources
      validate_connection!

      request({
        method: "resources/list",
        params: {}
      })
    end

    def read_resource(uri)
      validate_connection!

      request({
        method: "resources/read",
        params: { uri: uri }
      })
    end

    def list_tools
      validate_connection!

      request({
        method: "tools/list",
        params: {}
      })
    end

    def call_tool(params)
      validate_connection!

      request({
        method: "tools/call",
        params: params
      })
    end

    def list_prompts
      validate_connection!

      request({
        method: "prompts/list",
        params: {}
      })
    end

    def get_prompt(name, arguments = {})
      validate_connection!

      request({
        method: "prompts/get",
        params: {
          name: name,
          arguments: arguments
        }
      })
    end

    private

    def validate_connection!
      raise ConnectionError, "Client not connected" unless @connected
    end

    def request(req, timeout = 30)
      validate_connection!

      id = SecureRandom.uuid
      request_with_id = req.merge(id: id)

      future = Concurrent::Promises.resolvable_future
      @pending_requests[id] = future

      @transport.send_message(request_with_id.to_json)

      result = future.wait(timeout)
      @pending_requests.delete(id)

      if result.nil?
        raise TimeoutError, "Request timed out after #{timeout} seconds"
      end

      if result[:error]
        raise ResponseError, "Server error: #{result[:error][:message]} (#{result[:error][:code]})"
      end

      result[:result]
    end

    def handle_message(message)
      begin
        msg = JSON.parse(message, symbolize_names: true)

        if msg[:id] && @pending_requests.key?(msg[:id])
          future = @pending_requests[msg[:id]]
          future.fulfill(msg)
        end
      rescue JSON::ParserError => e
        # Log error
        puts "Error parsing message: #{e.message}"
      end
    end
  end
end

