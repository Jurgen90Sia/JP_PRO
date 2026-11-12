# frozen_string_literal: true

require 'json'

module JPCabinetPro
  module Persistence
    # Deterministic serialization and versioned storage hooks (scaffold).
    module Store
      SCHEMA_VERSION = 1

      class << self
        def serialize(payload)
          JSON.pretty_generate({ 'schema_version' => SCHEMA_VERSION, 'data' => payload })
        end

        def deserialize(json_str)
          parsed = JSON.parse(json_str)
          migrate(parsed)
        end

        def migrate(parsed)
          # Version migration placeholder.
          parsed
        end
      end
    end
  end
end
