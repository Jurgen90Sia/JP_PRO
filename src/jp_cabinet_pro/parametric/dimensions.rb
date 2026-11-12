# frozen_string_literal: true

module JPCabinetPro
  module Parametric
    # Dimension validation and internal dimension calculations (scaffold).
    # Finished/nominal/cutting semantics must be explicit per process; defaults here are placeholders.
    class Dimensions
      Result = Struct.new(:ok, :errors, :values, keyword_init: true)

      DEFAULTS = {
        width_mm: 800.0,
        height_mm: 720.0,
        depth_mm: 560.0,
        panel_thickness_mm: 18.0,
        shelf_count: 1,
        back_mount_type: 'recessed_back', # full_back|recessed_back|grooved_back|surface_mounted_back
        groove_depth_mm: 8.0,
        rear_inset_mm: 10.0
      }.freeze

      def self.validate(input)
        errors = []
        v = DEFAULTS.merge(symbolize(input))
        %i[width_mm height_mm depth_mm panel_thickness_mm].each do |k|
          errors << "#{k} must be > 0" unless v[k].is_a?(Numeric) && v[k] > 0
        end
        errors << 'shelf_count must be >= 0' unless v[:shelf_count].is_a?(Integer) && v[:shelf_count] >= 0
        errors << 'groove_depth_mm must be >= 0' unless v[:groove_depth_mm].is_a?(Numeric) && v[:groove_depth_mm] >= 0
        errors << 'rear_inset_mm must be >= 0' unless v[:rear_inset_mm].is_a?(Numeric) && v[:rear_inset_mm] >= 0

        internal = compute_internal(v) if errors.empty?
        Result.new(ok: errors.empty?, errors: errors, values: errors.empty? ? v.merge(internal: internal) : v)
      end

      def self.compute_internal(v)
        t = v[:panel_thickness_mm].to_f
        # Placeholder formulas; must be made construction-rule dependent per spec.
        {
          internal_width_mm: v[:width_mm].to_f - (2 * t),
          internal_height_mm: v[:height_mm].to_f - (2 * t),
          internal_depth_mm: v[:depth_mm].to_f - v[:rear_inset_mm].to_f
        }
      end

      def self.symbolize(h)
        (h || {}).each_with_object({}) { |(k, val), out| out[k.to_sym] = val }
      end
      private_class_method :symbolize
    end
  end
end
