# frozen_string_literal: true
# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: temporal/api/common/v1/grpc_status.proto

require 'google/protobuf'

require 'google/protobuf/any_pb'


descriptor_data = "\n(temporal/api/common/v1/grpc_status.proto\x12\x16temporal.api.common.v1\x1a\x19google/protobuf/any.proto\"R\n\nGrpcStatus\x12\x0c\n\x04\x63ode\x18\x01 \x01(\x05\x12\x0f\n\x07message\x18\x02 \x01(\t\x12%\n\x07\x64\x65tails\x18\x03 \x03(\x0b\x32\x14.google.protobuf.AnyB\x1e\xea\x02\x1bTemporalio::Api::Common::V1b\x06proto3"

pool = Google::Protobuf::DescriptorPool.generated_pool
pool.add_serialized_file(descriptor_data)

module Temporalio
  module Api
    module Common
      module V1
        GrpcStatus = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.common.v1.GrpcStatus").msgclass
      end
    end
  end
end