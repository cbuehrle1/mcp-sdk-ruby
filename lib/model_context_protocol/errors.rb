# lib/model_context_protocol/errors.rb
module ModelContextProtocol
  class Error < StandardError; end

  class ConnectionError < Error; end
  class InvalidRequestError < Error; end
  class ResponseError < Error; end
  class TimeoutError < Error; end
end
