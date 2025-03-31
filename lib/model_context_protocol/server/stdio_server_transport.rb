# lib/model_context_protocol/server/stdio_server_transport.rb
require 'json'

module ModelContextProtocol
  module Server
    class StdioServerTransport
      def initialize
        @message_callback = nil
      end

      def on_message(&block)
        @message_callback = block
      end

      def connect
        @stdin_thread = Thread.new do
          while line = gets
            @message_callback.call(line.strip) if @message_callback
          end
        end
      end

      def disconnect
        @stdin_thread.kill if @stdin_thread
      end

      def send_message(message)
        puts message
        STDOUT.flush
      end
    end
  end
end

