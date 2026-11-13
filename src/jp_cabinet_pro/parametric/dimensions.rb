# frozen_string_literal: true

module JPCabinetPro
  module Parametric
    # Dimension validation and internal dimension calculations.
    # Finished/nominal/cutting semantics must be explicit per process; values here treated as nominal/finished placeholders.
    class Dimensions
      Result = Struct.new(:ok, :errors, :values, :warnings, keyword_init: true)

      BACK_TYPES = %w[full_back recessed_back grooved_back surface_mounted_back hdf_grooved].freeze
      TOP_RULES = %w[top_between_sides top_over_sides].freeze
      BOTTOM_RULES = %w[bottom_between_sides bottom_under_sides].freeze

      DEFAULTS = {
        width_mm: 800.0,
        height_mm: 720.0,
        depth_mm: 560.0,
        panel_thickness_mm: 18.0,
        shelf_count: 1,
        partition_count: 0,
        top_construction: 'top_between_sides',
        bottom_construction: 'bottom_between_sides',
        back_mount_type: 'recessed_back',
        groove_depth_mm: 8.0,
        rear_inset_mm: 10.0,
        plinth_height_mm: 0.0,
        plinth_setback_mm: 50.0,
        legs_height_mm: 0.0,
        leg_count: 4,
        has_doors: false,
        has_drawers: false
      }.freeze

      def self.validate(input)
        errors = []
        warnings = []
        v = DEFAULTS.merge(symbolize(input || {}))
        normalize_numeric!(v)

        %i[width_mm height_mm depth_mm panel_thickness_mm].each do |k|
          errors << "#{k} must be > 0" unless v[k].is_a?(Numeric) && v[k] > 0
        end
        errors << 'shelf_count must be >= 0' unless v[:shelf_count].is_a?(Integer) && v[:shelf_count] >= 0
        errors << 'partition_count must be >= 0' unless v[:partition_count].is_a?(Integer) && v[:partition_count] >= 0
        %i[groove_depth_mm rear_inset_mm plinth_height_mm plinth_setback_mm legs_height_mm].each do |k|
          errors << "#{k} must be >= 0" unless v[k].is_a?(Numeric) && v[k] >= 0
        end
        errors << 'leg_count must be >= 0' unless v[:leg_count].is_a?(Integer) && v[:leg_count] >= 0
        errors << 'invalid back_mount_type' unless BACK_TYPES.include?(v[:back_mount_type].to_s)
        errors << 'invalid top_construction' unless TOP_RULES.include?(v[:top_construction].to_s)
        errors << 'invalid bottom_construction' unless BOTTOM_RULES.include?(v[:bottom_construction].to_s)

        t = v[:panel_thickness_mm].to_f
        w = v[:width_mm].to_f
        d = v[:depth_mm].to_f
        internal_w = w - 2 * t
        errors << 'width too small for panel thickness' if internal_w <= 0
        errors << 'depth too small for construction' if d <= t
        if v[:plinth_height_mm].to_f > 0 && v[:legs_height_mm].to_f > 0
          warnings << 'plinth and legs both set; prototype treats legs as additional support height'
        end

        internal = errors.empty? ? compute_internal(v) : nil
        Result.new(ok: errors.empty?, errors: errors, warnings: warnings, values: errors.empty? ? v.merge(internal: internal) : v)
      end

      def self.compute_internal(v)
        t = v[:panel_thickness_mm].to_f
        w = v[:width_mm].to_f
        h = v[:height_mm].to_f
        d = v[:depth_mm].to_f
        rear_inset = v[:rear_inset_mm].to_f
        groove = v[:groove_depth_mm].to_f
        back = v[:back_mount_type].to_s

        internal_w = w - (2 * t)
        internal_h = h
        internal_h -= t if v[:top_construction].to_s == 'top_between_sides'
        internal_h -= t if v[:bottom_construction].to_s == 'bottom_between_sides'

        internal_d = d
        case back
        when 'recessed_back'
          internal_d = d - rear_inset - t
        when 'grooved_back', 'hdf_grooved'
          internal_d = d - rear_inset - [groove, t].min
        when 'full_back', 'surface_mounted_back'
          internal_d = d - t
        end
        internal_d = 0.0 if internal_d.negative?

        plinth_h = v[:plinth_height_mm].to_f
        legs_h = v[:legs_height_mm].to_f
        clear_h = internal_h - plinth_h
        clear_h = 0.0 if clear_h.negative?

        {
          internal_width_mm: internal_w,
          internal_height_mm: internal_h,
          internal_depth_mm: internal_d,
          carcass_opening_width_mm: internal_w,
          carcass_opening_height_mm: internal_h,
          clear_internal_height_mm: clear_h,
          plinth_height_mm: plinth_h,
          legs_height_mm: legs_h,
          base_total_height_mm: plinth_h + legs_h
        }
      end

      def self.normalize_numeric!(v)
        %i[width_mm height_mm depth_mm panel_thickness_mm groove_depth_mm rear_inset_mm plinth_height_mm plinth_setback_mm legs_height_mm].each do |k|
          v[k] = Float(v[k]) if v[k].is_a?(String) && v[k] =~ /\A-?\d+(\.\d+)?\z/
        end
        %i[shelf_count partition_count leg_count].each do |k|
          if v[k].is_a?(String) && v[k] =~ /\A-?\d+\z/
            v[k] = Integer(v[k])
          end
        end
        %i[has_doors has_drawers].each do |k|
          v[k] = (v[k] == true || v[k].to_s == 'true' || v[k].to_s == '1')
        end
        v[:back_mount_type] = v[:back_mount_type].to_s
        v[:top_construction] = v[:top_construction].to_s
        v[:bottom_construction] = v[:bottom_construction].to_s
        # custom thickness convenience
        if v[:custom_thickness_mm] && v[:custom_thickness_mm].to_f > 0
          v[:panel_thickness_mm] = v[:custom_thickness_mm].to_f
        end
      end
      private_class_method :normalize_numeric!

      def self.symbolize(h)
        (h || {}).each_with_object({}) { |(k, val), out| out[k.to_sym] = val }
      end
      private_class_method :symbolize
    end
  end
end
