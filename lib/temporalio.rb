# Protoc wants all of its generated files on the LOAD_PATH
$LOAD_PATH << File.expand_path('./gen', File.dirname(__FILE__))

require 'temporalio/connection'
require 'temporalio/version'

module Temporalio
end
