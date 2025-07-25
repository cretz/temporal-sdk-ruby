# frozen_string_literal: true

require 'temporalio/api'
require 'temporalio/converters/payload_converter'
require 'temporalio/converters/raw_value'

module Temporalio
  module Converters
    class PayloadConverter
      # Payload converter that is a collection of {Encoding}s. When converting to a payload, it tries each encoding
      # converter in order until one works. The encoding converter is expected to set the +encoding+ metadata which is
      # then used to match to the proper encoding converter when converting back to a Ruby value.
      class Composite < PayloadConverter
        class ConverterNotFound < Error; end
        class EncodingNotSet < Error; end

        # @return [Hash<String, Encoding>] Encoding converters processed in order.
        attr_reader :converters

        # Create a payload converter with the given encoding converters processed in order.
        #
        # @param converters [Array<Encoding>] Encoding converters.
        def initialize(*converters)
          super()
          @converters = converters.each_with_object({}) do |converter, result|
            result[converter.encoding] = converter
            result
          end
          @converters.freeze
        end

        # Convert Ruby value to a payload by going over each encoding converter in order until one can convert.
        #
        # @param value [Object] Ruby value to convert.
        # @param hint [Object, nil] Hint, if any, to assist conversion.
        # @return [Api::Common::V1::Payload] Converted payload.
        # @raise [ConverterNotFound] If no converters can process the value.
        def to_payload(value, hint: nil)
          # As a special case, raw values just return the payload within
          return value.payload if value.is_a?(RawValue)

          converters.each_value do |converter|
            payload = converter.to_payload(value, hint:)
            return payload unless payload.nil?
          end
          raise ConverterNotFound, "Value of type #{value} has no known converter"
        end

        # Convert payload to Ruby value based on its +encoding+ metadata on the payload.
        #
        # @param payload [Api::Common::V1::Payload] Payload to convert.
        # @param hint [Object, nil] Hint, if any, to assist conversion.
        # @return [Object] Converted Ruby value.
        # @raise [EncodingNotSet] If encoding not set on the metadata.
        # @raise [ConverterNotFound] If no converter found for the encoding.
        def from_payload(payload, hint: nil)
          encoding = payload.metadata['encoding']
          raise EncodingNotSet, 'Missing payload encoding' unless encoding

          converter = converters[encoding]
          raise ConverterNotFound, "No converter for encoding #{encoding}" unless converter

          converter.from_payload(payload, hint:)
        end
      end
    end
  end
end
