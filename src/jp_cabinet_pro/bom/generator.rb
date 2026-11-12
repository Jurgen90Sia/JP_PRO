# frozen_string_literal: true

require 'securerandom'

module JPCabinetPro
  module Bom
    # BOM generation from canonical parts (scaffold). Aggregates only matching manufacturing properties.
    class Generator
      def generate(parts:, assembly_id: nil)
        enriched = parts.map do |p|
          p.merge(
            part_id: p[:id] || "part_#{SecureRandom.uuid}",
            parent_assembly_id: assembly_id,
            name: p[:name] || p[:role],
            revision: p[:revision] || 1
          )
        end
        aggregate(enriched)
      end

      def aggregate(items)
        groups = {}
        items.each do |it|
          key = [it[:name], it[:material_id], it[:thickness_mm], it[:width_mm], it[:height_mm],
                 it[:grain_direction], it[:edge_banding]]
          if groups[key]
            groups[key][:quantity] += (it[:quantity] || 1)
          else
            groups[key] = it.dup
          end
        end
        groups.values
      end
    end
  end
end
