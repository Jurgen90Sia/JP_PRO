# frozen_string_literal: true

module JPCabinetPro
  module Materials
    # Material catalog/assignment and quantity calculations.
    # Net/gross are separated; gross applies optional waste_factor (default 0.0, no assumption).
    class Engine
      Material = Struct.new(:id, :name, :thickness_variants_mm, :finish, :grain, :texture_scale, :texture_orientation, keyword_init: true)

      def initialize
        @catalog = {}
      end

      def upsert(material)
        m = material.is_a?(Hash) ? material : material.to_h
        id = m[:id] || m['id']
        @catalog[id] = m
        m
      end

      def fetch(id)
        @catalog[id]
      end

      def all
        @catalog.values
      end

      def assign(panel, material_id)
        p = panel.is_a?(Hash) ? panel.dup : panel.to_h.dup
        p[:material_id] = material_id
        p
      end

      # Computes net and gross area by [material_id, thickness_mm].
      # area_mm2 = width_mm * height_mm * quantity (panel face area, nominal).
      # gross = net * (1 + waste_factor). waste_factor must be provided explicitly if used.
      def quantities(parts, waste_factor: 0.0)
        wf = waste_factor.to_f
        raise ArgumentError, 'waste_factor must be >= 0' if wf.negative?
        net = Hash.new(0.0)
        (parts || []).each do |p|
          h = sym(p)
          mat = h[:material_id]
          th = h[:thickness_mm]
          area = h[:width_mm].to_f * h[:height_mm].to_f * (h[:quantity] || 1).to_f
          net[[mat, th]] += area
        end
        net_rows = net.map { |(m, t), a| { material_id: m, thickness_mm: t, area_mm2: round3(a) } }
                    .sort_by { |r| [r[:material_id].to_s, r[:thickness_mm].to_f] }
        gross_rows = net_rows.map { |r| r.merge(area_mm2: round3(r[:area_mm2] * (1.0 + wf))) }
        { net: net_rows, gross: gross_rows, waste_factor: wf }
      end

      private

      def sym(h)
        return {} unless h.is_a?(Hash)
        h.each_with_object({}) { |(k, v), out| out[k.to_sym] = v }
      end

      def round3(v)
        (v.to_f * 1000).round / 1000.0
      end
    end
  end
end
