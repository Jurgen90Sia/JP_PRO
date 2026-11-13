# frozen_string_literal: true

require 'json'
require 'time'

module JPCabinetPro
  module Persistence
    # Immutable calculation snapshots tied to revision IDs for manufacturing outputs.
    module Snapshot
      module_function

      def build(revision:, project_id: nil, assembly_id: nil, params: {}, bom: [], cutlist: [], view: nil,
                materials: nil, edge_banding: nil, nesting: nil, view_svg: nil, metadata: {})
        deep_freeze(
          {
            snapshot_version: 1,
            revision: revision,
            project_id: project_id,
            assembly_id: assembly_id,
            created_at: Time.now.utc.iso8601,
            params: deep_dup(params),
            bom: deep_dup(bom),
            cutlist: deep_dup(cutlist),
            view: deep_dup(view),
            materials: deep_dup(materials),
            edge_banding: deep_dup(edge_banding),
            nesting: deep_dup(nesting),
            view_svg: view_svg.is_a?(String) ? view_svg.dup.freeze : deep_dup(view_svg),
            metadata: deep_dup(metadata || {})
          }
        )
      end

      def serialize(snapshot)
        JSON.pretty_generate(snapshot)
      end

      def deep_dup(obj)
        case obj
        when Hash
          obj.each_with_object({}) { |(k, v), h| h[k] = deep_dup(v) }
        when Array
          obj.map { |v| deep_dup(v) }
        else
          begin
            obj.dup
          rescue StandardError
            obj
          end
        end
      end

      def deep_freeze(obj)
        case obj
        when Hash
          obj.each_value { |v| deep_freeze(v) }
        when Array
          obj.each { |v| deep_freeze(v) }
        end
        obj.freeze
      end
    end
  end
end
