# frozen_string_literal: true

module JPCabinetPro
  module Doors
    # Front/door engine scaffold. Config schema/validation based on stated spec; geometry pending.
    # AJ-observed behavior unverified (Phase 0 blocked). No fabricated manufacturer-specific dimensions.
    class FrontEngine
      TYPES = %w[single double three four].freeze
      SPLITS = %w[none horizontal vertical custom_proportional].freeze
      MOUNTINGS = %w[full_overlay partial_overlay inset lift_up bi_fold sliding].freeze
      HINGE_SIDES = %w[left right top bottom].freeze

      Result = Struct.new(:ok, :errors, :warnings, :config, keyword_init: true)

      def configure(cabinet_params, config)
        v = validate(config)
        return v unless v.ok
        # Geometry generation not implemented.
        Result.new(ok: false, errors: ['geometry_not_implemented'], warnings: v.warnings, config: v.config)
      end

      def validate(config)
        errors = []
        warnings = []
        c = symbolize(config || {})
        c[:type] = c[:type].to_s.empty? ? 'single' : c[:type].to_s
        c[:split] = c[:split].to_s.empty? ? 'none' : c[:split].to_s
        c[:mounting] = c[:mounting].to_s.empty? ? 'full_overlay' : c[:mounting].to_s

        errors << 'invalid front type' unless TYPES.include?(c[:type])
        errors << 'invalid split' unless SPLITS.include?(c[:split])
        errors << 'invalid mounting' unless MOUNTINGS.include?(c[:mounting])

        if c[:hinge_side]
          errors << 'invalid hinge_side' unless HINGE_SIDES.include?(c[:hinge_side].to_s)
        end
        %i[gap_mm front_thickness_mm opening_angle_deg].each do |k|
          next unless c.key?(k)
          errors << "#{k} must be >= 0" unless c[k].is_a?(Numeric) && c[k] >= 0
        end
        if c[:type] == 'single' && c[:split] != 'none'
          warnings << 'split ignored for single door type (scaffold rule)'
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
