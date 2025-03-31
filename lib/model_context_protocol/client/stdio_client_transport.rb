# lib/model_context_protocol/client/stdio_client_transport.rb
require 'json'
require 'open3'

module ModelContextProtocol
  module Client
    class StdioClientTransport
      def initialize(command:, args: [])
        @command = command
        @args = args
        @message_callback = nil
      end

      def on_message(&block)
        @message_callback = block
      end

      def connect
        @stdin, @stdout, @stderr, @wait_thr = Open3.popen3(@command, *@args)

        @stdout_thread = Thread.new do
          while line = @stdout.gets
            @message_callback.call(line.strip) if @message_callback
          end
        end

        @stderr_thread = Thread.new do
          while line = @stderr.gets
            # Log error output
            puts "STDERR: #{line.strip}"
          end
        end
      end

      def disconnect
        @stdin.close if @stdin && !@stdin.closed?
        @stdout_thread.kill if @stdout_thread
        @stderr_thread.kill if @stderr_thread

        @stdout.close if @stdout && !@stdout.closed?
        @stderr.close if @stderr && !@stderr.closed?

        @wait_thr.kill if @wait_thr
      end

      def send_message(message)
        @stdin.puts(message)
        @stdin.flush
      end
    end
  end
end
