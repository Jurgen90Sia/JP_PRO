# frozen_string_literal: true

module JPCabinetPro
  module EdgeBanding
    # Per-edge banding stored independently; totals by material/thickness. Dimensional compensation is process-specific (not applied globally).
    class Engine
      EDGES = %i[left right top bottom].freeze

      def normalize(bands = {})
        EDGES.each_with_object({}) { |e, h| h[e] = bands[e] || bands[e.to_s] }
      end

      def total_length(parts)
        totals = Hash.new(0.0)
        parts.each do |p|
          bands = normalize(p[:edge_banding] || {})
          dims = edge_lengths(p)
          bands.each do |edge, band|
            next unless band
            key = [band[:material_id] || band['material_id'], band[:thickness_mm] || band['thickness_mm']]
            totals[key] += dims[edge].to_f * (p[:quantity] || 1)
          end
        end
        totals.map { |(mat, th), len| { material_id: mat, thickness_mm: th, length_mm: len } }
      end

      private

      # Placeholder mapping; depends on part orientation/role semantics.
      def edge_lengths(p)
        w = p[:width_mm].to_f
        h = p[:height_mm].to_f
        { left: h, right: h, top: w, bottom: w }
      end
    end
  end
end
