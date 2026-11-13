# frozen_string_literal: true

module JPCabinetPro
  module Hardware
    # Structured hardware data/BOM integration. Adapter-based catalog; no fabricated manufacturer dimensions.
    class Engine
      KNOWN_TYPES = %w[hinge handle drawer_slide shelf_support connector adjustable_leg plinth_clip lift_mechanism fitting].freeze

      def bom_lines(items)
        (items || []).map do |it|
          h = symbolize(it.is_a?(Hash) ? it : it.to_h)
          {
            id: h[:id],
            type: h[:type],
            catalog_ref: h[:catalog_ref],
            quantity: (h[:quantity] || 1).to_i,
            placement: h[:placement],
            properties: h[:properties]
          }
        end
      end

      def validate(items, _cabinet = nil)
        errors = []
        warnings = []
        Array(items).each_with_index do |it, i|
          h = symbolize(it.is_a?(Hash) ? it : it.to_h)
          errors << "items[#{i}].type required" if h[:type].to_s.empty?
          if !h[:type].to_s.empty? && !KNOWN_TYPES.include?(h[:type].to_s)
            warnings << "items[#{i}].type '#{h[:type]}' not in known types (allowed as custom)"
          end
          q = h[:quantity]
          errors << "items[#{i}].quantity must be >= 1" if !q.nil? && !(q.is_a?(Numeric) && q >= 1)
          warnings << "items[#{i}] missing catalog_ref (adapter-based catalog recommended)" if h[:catalog_ref].nil?
        end
        { ok: errors.empty?, warnings: warnings, errors: errors }
      end

      def aggregate_bom(items)
        groups = {}
        bom_lines(items).each do |line|
          key = [line[:type], line[:catalog_ref], normalize_placement(line[:placement]), line[:properties]]
          if groups[key]
            groups[key][:quantity] += line[:quantity]
          else
            groups[key] = line.dup
          end
        end
        groups.values
      end

      private

      def normalize_placement(p)
        return nil if p.nil?
        p.is_a?(Hash) ? p.sort.to_h : p
      end

      def symbolize(h)
        return {} unless h.is_a?(Hash)
        h.each_with_object({}) { |(k, v), out| out[k.to_sym] = v }
      end
    end
  end
end
