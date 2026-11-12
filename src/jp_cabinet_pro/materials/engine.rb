# frozen_string_literal: true

module JPCabinetPro
  module Materials
    # Material catalog/assignment/quantity scaffold. Net/gross separation required; calculations pending.
    class Engine
      Material = Struct.new(:id, :name, :thickness_variants_mm, :finish, :grain, :texture_scale, :texture_orientation, keyword_init: true)

      def initialize
        @catalog = {}
      end

      def upsert(material)
        @catalog[material[:id] || material.id] = material
      end

      def fetch(id)
        @catalog[id]
      end

      def assign(panel, material_id)
        panel.merge(material_id: material_id)
      end

      # Returns placeholder structure; real net/gross calc depends on canonical parts and processes.
      def quantities(_parts)
        { net: {}, gross: {}, status: 'scaffold' }
      end
    end
  end
end
