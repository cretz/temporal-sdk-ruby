# frozen_string_literal: true

module Temporalio
  module Workflow
    UpdateInfo = Struct.new(
      :id,
      :name,
      keyword_init: true
    )
  end
end
