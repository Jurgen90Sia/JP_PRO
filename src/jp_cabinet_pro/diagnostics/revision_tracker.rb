# frozen_string_literal: true

module JPCabinetPro
  module Diagnostics
    # Tracks revision and downstream invalidation state per assembly.
    # Dimension changes must invalidate: geometry, parts, materials, edge_banding, hardware,
    # bom, cutlist, nesting, drawings, reports.
    class RevisionTracker
      OUTPUTS = %i[geometry parts materials edge_banding hardware bom cutlist nesting drawings reports].freeze

      def initialize
        @state = {}
      end

      def touch!(assembly_id, revision)
        entry = (@state[assembly_id] ||= { revision: 0, valid: {} })
        entry[:revision] = revision
        OUTPUTS.each { |k| entry[:valid][k] = false }
        entry
      end

      def mark_valid!(assembly_id, *outputs)
        entry = @state[assembly_id]
        return nil unless entry
        outputs.each { |o| entry[:valid][o.to_sym] = true if OUTPUTS.include?(o.to_sym) }
        entry
      end

      def invalidate!(assembly_id, *outputs)
        entry = @state[assembly_id]
        return nil unless entry
        list = outputs.empty? ? OUTPUTS : outputs.map(&:to_sym)
        list.each { |o| entry[:valid][o] = false if OUTPUTS.include?(o) }
        entry
      end

      def status(assembly_id)
        @state[assembly_id]
      end

      def snapshot(assembly_id)
        entry = status(assembly_id)
        return nil unless entry
        {
          revision: entry[:revision],
          valid: entry[:valid].dup,
          stale: OUTPUTS.reject { |o| entry[:valid][o] }
        }
      end
    end
  end
end
