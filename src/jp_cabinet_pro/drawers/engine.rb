# frozen_string_literal: true

module JPCabinetPro
  module Drawers
    # Drawer system scaffold. Adapter-based mechanism catalog; no fabricated manufacturer mounting dimensions.
    # AJ-observed behavior unverified (Phase 0 blocked).
    class Engine
      MOUNTINGS = %w[overlay inset].freeze
      Result = Struct.new(:ok, :errors, :warnings, :config, keyword_init: true)

      def configure(_cabinet_params, config)
        v = validate(config)
        return v unless v.ok
        Result.new(ok: false, errors: ['geometry_not_implemented'], warnings: v.warnings, config: v.config)
      end

      def validate(config)
        errors = []
        warnings = []
        c = symbolize(config || {})
        c[:count] = c.key?(:count) ? c[:count].to_i : 1
        c[:mounting] = c[:mounting].to_s.empty? ? 'overlay' : c[:mounting].to_s

        errors << 'count must be >= 1' unless c[:count].is_a?(Integer) && c[:count] >= 1
        errors << 'invalid mounting' unless MOUNTINGS.include?(c[:mounting])
        if c[:front_heights_mm]
          unless c[:front_heights_mm].is_a?(Array) && c[:front_heights_mm].all? { |x| x.is_a?(Numeric) && x > 0 }
            errors << 'front_heights_mm must be array of positive numbers'
          end
        end
        %i[slide_clearance_mm box_depth_mm bottom_thickness_mm].each do |k|
          next unless c.key?(k)
          errors << "#{k} must be >= 0" unless c[k].is_a?(Numeric) && c[k] >= 0
        end
        if c[:catalog_ref].nil?
          warnings << 'no mechanism catalog_ref specified (adapter-based catalog required for verified mounting data)'
        end
        Result.new(ok: errors.empty?, errors: errors, warnings: warnings, config: c)
      end

      private

      def symbolize(h)
        h.each_with_object({}) { |(k, v), out| out[k.to_sym] = v }
      end
    end
  end
end
