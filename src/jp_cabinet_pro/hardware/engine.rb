# frozen_string_literal: true

module JPCabinetPro
  module Hardware
    # Structured hardware data/BOM integration. Adapter-based catalog; no fabricated manufacturer dimensions.
    class Engine
      Item = Struct.new(:id, :type, :catalog_ref, :placement, :quantity, :geometry_ref, :properties, keyword_init: true)

      def bom_lines(items)
        (items || []).map do |it|
          h = it.is_a?(Hash) ? it : it.to_h
          { id: h[:id], type: h[:type], catalog_ref: h[:catalog_ref], quantity: h[:quantity] || 1, placement: h[:placement] }
        end
      end

      def validate(_items, _cabinet)
        # Placeholder: check compatibility/clearances when rules and verified data exist.
        { ok: true, warnings: [], errors: [] }
      end
    end
  end
end
