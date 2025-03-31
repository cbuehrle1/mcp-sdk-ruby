# lib/model_context_protocol/types.rb
require 'json'
require 'dry-schema'
require 'dry-validation'

module ModelContextProtocol
  module Types
    # Implementation info schema
    ImplementationInfo = Dry::Schema.Params do
      required(:name).filled(:string)
      required(:version).filled(:string)
    end

    # Error schema
    ErrorSchema = Dry::Schema.Params do
      required(:code).filled(:integer)
      required(:message).filled(:string)
      optional(:data).value(:hash)
    end

    # Response schemas
    class ResourceContent
      attr_reader :uri, :mime_type, :text, :data

      def initialize(uri:, mime_type:, text: nil, data: nil)
        @uri = uri
        @mime_type = mime_type
        @text = text
        @data = data
      end

      def to_h
        hash = {
          uri: @uri,
          mimeType: @mime_type
        }
        hash[:text] = @text if @text
        hash[:data] = @data if @data
        hash
      end

      def self.from_h(hash)
        new(
          uri: hash[:uri] || hash["uri"],
          mime_type: hash[:mimeType] || hash["mimeType"],
          text: hash[:text] || hash["text"],
          data: hash[:data] || hash["data"]
        )
      end
    end

    class Content
      attr_reader :type, :text, :data

      def initialize(type:, text: nil, data: nil)
        @type = type
        @text = text
        @data = data
      end

      def to_h
        hash = { type: @type }
        hash[:text] = @text if @text
        hash[:data] = @data if @data
        hash
      end

      def self.from_h(hash)
        new(
          type: hash[:type] || hash["type"],
          text: hash[:text] || hash["text"],
          data: hash[:data] || hash["data"]
        )
      end
    end

    # Request schemas
    ListResourcesRequestSchema = Dry::Schema.Params do
      optional(:id).filled(:string)
    end

    ReadResourceRequestSchema = Dry::Schema.Params do
      required(:uri).filled(:string)
      optional(:id).filled(:string)
    end

    ListToolsRequestSchema = Dry::Schema.Params do
      optional(:id).filled(:string)
    end

    CallToolRequestSchema = Dry::Schema.Params do
      required(:name).filled(:string)
      optional(:arguments).value(:hash)
      optional(:id).filled(:string)
    end

    ListPromptsRequestSchema = Dry::Schema.Params do
      optional(:id).filled(:string)
    end

    GetPromptRequestSchema = Dry::Schema.Params do
      required(:name).filled(:string)
      optional(:arguments).value(:hash)
      optional(:id).filled(:string)
    end

    # Response schemas
    ListResourcesResponseSchema = Dry::Schema.Params do
      required(:resources).value(:array)
      optional(:id).value(:string)
    end

    ReadResourceResponseSchema = Dry::Schema.Params do
      required(:contents).value(:array)
      optional(:id).value(:string)
    end

    ListToolsResponseSchema = Dry::Schema.Params do
      required(:tools).value(:array)
      optional(:id).value(:string)
    end

    CallToolResponseSchema = Dry::Schema.Params do
      required(:content).value(:array)
      required(:is_error).value(:bool)
      optional(:id).value(:string)
    end

    ListPromptsResponseSchema = Dry::Schema.Params do
      required(:prompts).value(:array)
      optional(:id).value(:string)
    end

    GetPromptResponseSchema = Dry::Schema.Params do
      required(:messages).value(:array)
      optional(:id).value(:string)
    end
  end
end
