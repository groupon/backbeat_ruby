require "backbeat"
require "backbeat/action"
require "backbeat/serializer/activity"
require "backbeat/serializer/findable_activity"
require "active_support/inflector"

module Backbeat
  class Packer
    def self.unpack_action(data)
      action_data = data[:client_data]
      action_data[:class] = Inflector.constantize(action_data[:class])
      action_data[:method] = action_data[:method].to_sym
      serializer = Inflector.constantize(action_data[:serializer])
      Action.build(serializer.new(action_data))
    end

    def self.pack_action(action, mode, fires_at = nil)
      action_hash = action.to_hash
      {
        name: action_hash[:name],
        mode: mode,
        type: :none,
        fires_at: fires_at,
        client_data: action_hash
      }
    end

    def self.success_response(result)
      rpc_response({ result: result })
    end

    GENERIC_RPC_ERROR_CODE = -32000

    def self.error_response(error)
      rpc_response({
        error: {
          code: GENERIC_RPC_ERROR_CODE,
          message: error.message,
          data: (error.backtrace.take(5) if error.backtrace)
        }
      })
    end

    def self.rpc_response(params)
      {
        jsonrpc: "2.0",
        result: nil,
        error: nil,
        id: nil
      }.merge(params)
    end

    def self.subject_to_string(subject)
      case
      when subject.is_a?(String)
        subject
      when subject.is_a?(Hash)
        subject.to_json
      when subject.respond_to?(:id)
        { id: subject.id, class: subject.class }.to_json
      when subject.respond_to?(:to_hash)
        subject.to_hash.to_json
      else
        subject.to_json
      end
    end

    def self.underscore_keys(data)
      case data
      when Array
        data.map { |v| underscore_keys(v) }
      when Hash
        underscored_data = data.map do |(k, v)|
          [Inflector.underscore(k.to_s).to_sym, underscore_keys(v)]
        end
        Hash[underscored_data]
      else
        data
      end
    end

    class Inflector
      extend ActiveSupport::Inflector
    end
  end
end
