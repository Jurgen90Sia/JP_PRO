# frozen_string_literal: true

module JPCabinetPro
  module Cabinet
    # Cabinet construction/rebuild engine (scaffold).
    # Real geometry rebuild must be construction-rule dependent and transaction-safe via Adapter.
    class Construction
      def initialize(adapter:)
        @adapter = adapter
      end

      def rebuild(params:, existing: nil)
        # Placeholder: compute part set from params; in SketchUp this mutates entities in a transaction.
        # Must preserve valid material assignments/component identity and support rollback on failure.
        parts = build_parts(params)
        { ok: true, parts: parts, replaced: !existing.nil? }
      end

      def build_parts(params)
        w = params[:width_mm].to_f
        h = params[:height_mm].to_f
        d = params[:depth_mm].to_f
        t = params[:panel_thickness_mm].to_f
        shelves = params[:shelf_count].to_i
        base = [
          part('side_left', w: t, h: h, t: d),
          part('side_right', w: t, h: h, t: d),
          part('bottom', w: [w - 2 * t, 0].max, h: t, t: d),
          part('top', w: [w - 2 * t, 0].max, h: t, t: d),
          part('back', w: [w - 2 * t, 0].max, h: [h - 2 * t, 0].max, t: t)
        ]
        shelves.times { |i| base << part("shelf_#{i + 1}", w: [w - 2 * t, 0].max, h: t, t: [d - params[:rear_inset_mm].to_f, 0].max) }
        base
      end

      private

      def part(role, w:, h:, t:)
        {
          id: nil, # assigned by BOM/model layer for stable IDs
          role: role,
          width_mm: w,
          height_mm: h,
          thickness_mm: t,
          material_id: nil,
          grain_direction: nil,
          edge_banding: { left: nil, right: nil, top: nil, bottom: nil },
          quantity: 1,
          manufacturing_status: 'draft',
          revision: nil
        }
      end
    end
  end
end
