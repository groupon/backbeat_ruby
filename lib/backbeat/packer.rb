require "backbeat"
require "backbeat/activity"
require "backbeat/serializer/activity"
require "backbeat/serializer/findable_activity"
require "active_support/inflector"

module Backbeat
  class Packer
    def self.unpack_activity(data)
      activity_data = data[:client_data]
      activity_data[:class] = Inflector.constantize(activity_data[:class])
      activity_data[:method] = activity_data[:method].to_sym
      serializer = Inflector.constantize(activity_data[:serializer])
      Activity.build(serializer.new(activity_data))
    end

    def self.pack_activity(activity, mode, fires_at = nil)
      activity_hash = activity.to_hash
      {
        name: activity_hash[:name],
        mode: mode,
        type: :none,
        fires_at: fires_at,
        client_data: activity_hash
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
