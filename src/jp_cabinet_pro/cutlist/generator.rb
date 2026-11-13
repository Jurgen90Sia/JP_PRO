# frozen_string_literal: true

module JPCabinetPro
  module Cutlist
    # Cut list derived from BOM snapshot.
    # Dimension fields are nominal placeholders; finished/nominal/cutting semantics must be explicit per process.
    class Generator
      def generate(bom_items)
        (bom_items || []).map do |it|
          it = symbolize(it)
          {
            part_id: it[:part_id],
            part_name: it[:name],
            material: it[:material_id],
            thickness: it[:thickness_mm],
            length: it[:height_mm],
            width: it[:width_mm],
            quantity: it[:quantity] || 1,
            grain_direction: it[:grain_direction],
            edge_banding: it[:edge_banding],
            assembly_id: it[:parent_assembly_id],
            barcode_qr: it[:part_id],
            manufacturing_notes: it[:notes],
            size_kind: 'nominal'
          }
        end
      end

      private

      def symbolize(h)
        return h unless h.is_a?(Hash)
        h.each_with_object({}) { |(k, v), out| out[k.to_sym] = v }
      end
    end
  end
end
