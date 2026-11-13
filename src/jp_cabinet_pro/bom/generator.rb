# frozen_string_literal: true

require 'securerandom'

module JPCabinetPro
  module Bom
    # BOM generation from canonical parts. Aggregates only matching manufacturing properties.
    class Generator
      def generate(parts:, assembly_id: nil)
        enriched = (parts || []).map do |p|
          p = symbolize(p)
          p.merge(
            part_id: p[:id] || p[:part_id] || "part_#{SecureRandom.uuid}",
            parent_assembly_id: p[:parent_assembly_id] || assembly_id,
            name: p[:name] || p[:role],
            revision: p[:revision] || 1
          )
        end
        aggregate(enriched)
      end

      def aggregate(items)
        groups = {}
        items.each do |it|
          key = [
            it[:name], it[:material_id], it[:thickness_mm],
            round_mm(it[:width_mm]), round_mm(it[:height_mm]),
            it[:grain_direction], normalize_banding(it[:edge_banding])
          ]
          if groups[key]
            groups[key][:quantity] += (it[:quantity] || 1)
          else
            groups[key] = it.dup
            groups[key][:quantity] = it[:quantity] || 1
          end
        end
        groups.values
      end

      private

      def round_mm(v)
        return nil if v.nil?
        (v.to_f * 1000).round / 1000.0
      end

      def normalize_banding(b)
        return { left: nil, right: nil, top: nil, bottom: nil } unless b
        b = symbolize(b)
        { left: b[:left], right: b[:right], top: b[:top], bottom: b[:bottom] }
      end

      def symbolize(h)
        return h unless h.is_a?(Hash)
        h.each_with_object({}) { |(k, v), out| out[k.to_sym] = v.is_a?(Hash) ? symbolize(v) : v }
      end
    end
  end
end
