# lib/model_context_protocol/server/resource_template.rb
require 'uri'

module ModelContextProtocol
  module Server
    class ResourceTemplate
      def initialize(template, capabilities = {})
        @template = template
        @capabilities = capabilities
        @parts = parse_template(template)
      end

      def match(uri)
        uri_obj = URI(uri)
        template_obj = URI(@template.gsub(/{([^}]+)}/, '*'))

        return nil unless uri_obj.scheme == template_obj.scheme

        pattern = Regexp.new('^' + Regexp.escape(@template).gsub(/\\\{([^}]+)\\\}/, '(?<\\1>[^/]+)') + '$')
        match = pattern.match(uri)

        return nil unless match

        # Extract parameters
        params = {}
        match.names.each do |name|
          params[name] = match[name]
        end

        params
      end

      def to_h
        {
          template: @template,
          capabilities: @capabilities
        }
      end

      private

      def parse_template(template)
        parts = []
        remainder = template

        while remainder.include?('{')
          start = remainder.index('{')
          end_pos = remainder.index('}', start)

          if end_pos.nil?
            raise ArgumentError, "Unclosed { in template: #{template}"
          end

          if start > 0
            parts << { type: :literal, value: remainder[0...start] }
          end

          param_name = remainder[(start + 1)...end_pos]
          parts << { type: :parameter, name: param_name }

          remainder = remainder[(end_pos + 1)..-1]
        end

        if !remainder.empty?
          parts << { type: :literal, value: remainder }
        end

        parts
      end
    end
  end
end
