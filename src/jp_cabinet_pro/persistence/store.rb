# frozen_string_literal: true

require 'json'
require 'fileutils'

module JPCabinetPro
  module Persistence
    # Deterministic serialization and versioned storage hooks.
    module Store
      SCHEMA_VERSION = 1

      class << self
        def serialize(payload, schema_version: SCHEMA_VERSION)
          JSON.pretty_generate({ 'schema_version' => schema_version, 'data' => payload })
        end

        def deserialize(json_str)
          parsed = JSON.parse(json_str)
          migrate(parsed)
        end

        def migrate(parsed)
          # Version migration placeholder. Ensure envelope shape.
          return { 'schema_version' => SCHEMA_VERSION, 'data' => parsed } unless parsed.is_a?(Hash)
          parsed['schema_version'] ||= 0
          parsed['data'] = parsed['data'] || parsed.reject { |k, _| k == 'schema_version' }
          parsed
        end

        def save(path, payload, schema_version: SCHEMA_VERSION)
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, serialize(payload, schema_version: schema_version))
          { ok: true, path: path }
        rescue StandardError => e
          { ok: false, error: e.message }
        end

        def load(path)
          return { ok: false, error: 'not_found' } unless File.exist?(path)
          data = deserialize(File.read(path))
          { ok: true, data: data }
        rescue StandardError => e
          { ok: false, error: e.message }
        end
      end
    end
  end
end
