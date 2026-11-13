# frozen_string_literal: true

module JPCabinetPro
  module EdgeBanding
    # Per-edge banding stored independently; totals by material/thickness.
    # Dimensional compensation is process-specific (not applied globally).
    class Engine
      EDGES = %i[left right top bottom].freeze

      def normalize(bands = {})
        h = symbolize(bands || {})
        EDGES.each_with_object({}) { |e, out| out[e] = h[e] }
      end

      def total_length(parts)
        totals = Hash.new(0.0)
        (parts || []).each do |p|
          ph = symbolize(p)
          bands = normalize(ph[:edge_banding] || {})
          dims = edge_lengths(ph)
          qty = (ph[:quantity] || 1).to_f
          bands.each do |edge, band|
            next unless band
            bh = symbolize(band)
            key = [bh[:material_id], bh[:thickness_mm]]
            totals[key] += dims[edge].to_f * qty
          end
        end
        totals.map { |(mat, th), len| { material_id: mat, thickness_mm: th, length_mm: round3(len) } }
              .sort_by { |r| [r[:material_id].to_s, r[:thickness_mm].to_f] }
      end

      private

      # Placeholder mapping; depends on part orientation/role semantics.
      def edge_lengths(p)
        w = p[:width_mm].to_f
        h = p[:height_mm].to_f
        { left: h, right: h, top: w, bottom: w }
      end

      def symbolize(h)
        return {} unless h.is_a?(Hash)
        h.each_with_object({}) { |(k, v), out| out[k.to_sym] = v.is_a?(Hash) ? symbolize(v) : v }
      end

      def round3(v)
        (v.to_f * 1000).round / 1000.0
      end
    end
  end
end
