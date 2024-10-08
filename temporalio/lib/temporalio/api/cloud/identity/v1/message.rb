# frozen_string_literal: true
# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: temporal/api/cloud/identity/v1/message.proto

require 'google/protobuf'

require 'google/protobuf/timestamp_pb'


descriptor_data = "\n,temporal/api/cloud/identity/v1/message.proto\x12\x1etemporal.api.cloud.identity.v1\x1a\x1fgoogle/protobuf/timestamp.proto\"\x1d\n\rAccountAccess\x12\x0c\n\x04role\x18\x01 \x01(\t\"%\n\x0fNamespaceAccess\x12\x12\n\npermission\x18\x01 \x01(\t\"\x95\x02\n\x06\x41\x63\x63\x65ss\x12\x45\n\x0e\x61\x63\x63ount_access\x18\x01 \x01(\x0b\x32-.temporal.api.cloud.identity.v1.AccountAccess\x12Y\n\x12namespace_accesses\x18\x02 \x03(\x0b\x32=.temporal.api.cloud.identity.v1.Access.NamespaceAccessesEntry\x1ai\n\x16NamespaceAccessesEntry\x12\x0b\n\x03key\x18\x01 \x01(\t\x12>\n\x05value\x18\x02 \x01(\x0b\x32/.temporal.api.cloud.identity.v1.NamespaceAccess:\x02\x38\x01\"Q\n\x08UserSpec\x12\r\n\x05\x65mail\x18\x01 \x01(\t\x12\x36\n\x06\x61\x63\x63\x65ss\x18\x02 \x01(\x0b\x32&.temporal.api.cloud.identity.v1.Access\"p\n\nInvitation\x12\x30\n\x0c\x63reated_time\x18\x01 \x01(\x0b\x32\x1a.google.protobuf.Timestamp\x12\x30\n\x0c\x65xpired_time\x18\x02 \x01(\x0b\x32\x1a.google.protobuf.Timestamp\"\xb9\x02\n\x04User\x12\n\n\x02id\x18\x01 \x01(\t\x12\x18\n\x10resource_version\x18\x02 \x01(\t\x12\x36\n\x04spec\x18\x03 \x01(\x0b\x32(.temporal.api.cloud.identity.v1.UserSpec\x12\r\n\x05state\x18\x04 \x01(\t\x12\x1a\n\x12\x61sync_operation_id\x18\x05 \x01(\t\x12>\n\ninvitation\x18\x06 \x01(\x0b\x32*.temporal.api.cloud.identity.v1.Invitation\x12\x30\n\x0c\x63reated_time\x18\x07 \x01(\x0b\x32\x1a.google.protobuf.Timestamp\x12\x36\n\x12last_modified_time\x18\x08 \x01(\x0b\x32\x1a.google.protobuf.Timestamp\"U\n\rUserGroupSpec\x12\x0c\n\x04name\x18\x01 \x01(\t\x12\x36\n\x06\x61\x63\x63\x65ss\x18\x02 \x01(\x0b\x32&.temporal.api.cloud.identity.v1.Access\"\x83\x02\n\tUserGroup\x12\n\n\x02id\x18\x01 \x01(\t\x12\x18\n\x10resource_version\x18\x02 \x01(\t\x12;\n\x04spec\x18\x03 \x01(\x0b\x32-.temporal.api.cloud.identity.v1.UserGroupSpec\x12\r\n\x05state\x18\x04 \x01(\t\x12\x1a\n\x12\x61sync_operation_id\x18\x05 \x01(\t\x12\x30\n\x0c\x63reated_time\x18\x06 \x01(\x0b\x32\x1a.google.protobuf.Timestamp\x12\x36\n\x12last_modified_time\x18\x07 \x01(\x0b\x32\x1a.google.protobuf.Timestamp\"\x8d\x02\n\x0eServiceAccount\x12\n\n\x02id\x18\x01 \x01(\t\x12\x18\n\x10resource_version\x18\x02 \x01(\t\x12@\n\x04spec\x18\x03 \x01(\x0b\x32\x32.temporal.api.cloud.identity.v1.ServiceAccountSpec\x12\r\n\x05state\x18\x04 \x01(\t\x12\x1a\n\x12\x61sync_operation_id\x18\x05 \x01(\t\x12\x30\n\x0c\x63reated_time\x18\x06 \x01(\x0b\x32\x1a.google.protobuf.Timestamp\x12\x36\n\x12last_modified_time\x18\x07 \x01(\x0b\x32\x1a.google.protobuf.Timestamp\"o\n\x12ServiceAccountSpec\x12\x0c\n\x04name\x18\x01 \x01(\t\x12\x36\n\x06\x61\x63\x63\x65ss\x18\x02 \x01(\x0b\x32&.temporal.api.cloud.identity.v1.Access\x12\x13\n\x0b\x64\x65scription\x18\x03 \x01(\t\"\xfd\x01\n\x06\x41piKey\x12\n\n\x02id\x18\x01 \x01(\t\x12\x18\n\x10resource_version\x18\x02 \x01(\t\x12\x38\n\x04spec\x18\x03 \x01(\x0b\x32*.temporal.api.cloud.identity.v1.ApiKeySpec\x12\r\n\x05state\x18\x04 \x01(\t\x12\x1a\n\x12\x61sync_operation_id\x18\x05 \x01(\t\x12\x30\n\x0c\x63reated_time\x18\x06 \x01(\x0b\x32\x1a.google.protobuf.Timestamp\x12\x36\n\x12last_modified_time\x18\x07 \x01(\x0b\x32\x1a.google.protobuf.Timestamp\"\xa0\x01\n\nApiKeySpec\x12\x10\n\x08owner_id\x18\x01 \x01(\t\x12\x12\n\nowner_type\x18\x02 \x01(\t\x12\x14\n\x0c\x64isplay_name\x18\x03 \x01(\t\x12\x13\n\x0b\x64\x65scription\x18\x04 \x01(\t\x12/\n\x0b\x65xpiry_time\x18\x05 \x01(\x0b\x32\x1a.google.protobuf.Timestamp\x12\x10\n\x08\x64isabled\x18\x06 \x01(\x08\x42\xac\x01\n!io.temporal.api.cloud.identity.v1B\x0cMessageProtoP\x01Z-go.temporal.io/api/cloud/identity/v1;identity\xaa\x02 Temporalio.Api.Cloud.Identity.V1\xea\x02$Temporalio::Api::Cloud::Identity::V1b\x06proto3"

pool = Google::Protobuf::DescriptorPool.generated_pool
pool.add_serialized_file(descriptor_data)

module Temporalio
  module Api
    module Cloud
      module Identity
        module V1
          AccountAccess = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.cloud.identity.v1.AccountAccess").msgclass
          NamespaceAccess = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.cloud.identity.v1.NamespaceAccess").msgclass
          Access = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.cloud.identity.v1.Access").msgclass
          UserSpec = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.cloud.identity.v1.UserSpec").msgclass
          Invitation = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.cloud.identity.v1.Invitation").msgclass
          User = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.cloud.identity.v1.User").msgclass
          UserGroupSpec = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.cloud.identity.v1.UserGroupSpec").msgclass
          UserGroup = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.cloud.identity.v1.UserGroup").msgclass
          ServiceAccount = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.cloud.identity.v1.ServiceAccount").msgclass
          ServiceAccountSpec = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.cloud.identity.v1.ServiceAccountSpec").msgclass
          ApiKey = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.cloud.identity.v1.ApiKey").msgclass
          ApiKeySpec = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.cloud.identity.v1.ApiKeySpec").msgclass
        end
      end
    end
  end
end
