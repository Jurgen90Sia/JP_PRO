# frozen_string_literal: true

module JPCabinetPro
  module Doors
    # Front/door engine. Computes front panel layouts/dimensions (prototype, spec-derived).
    # AJ-observed behavior unverified (Phase 0 blocked). No fabricated manufacturer-specific dimensions.
    # Geometry creation in SketchUp is not implemented here.
    class FrontEngine
      TYPES = %w[single double three four].freeze
      SPLITS = %w[none horizontal vertical custom_proportional].freeze
      MOUNTINGS = %w[full_overlay partial_overlay inset lift_up bi_fold sliding].freeze
      HINGE_SIDES = %w[left right top bottom].freeze

      TYPE_COUNT = { 'single' => 1, 'double' => 2, 'three' => 3, 'four' => 4 }.freeze

      Result = Struct.new(:ok, :errors, :warnings, :config, :fronts, keyword_init: true)

      def configure(cabinet_params, config)
        v = validate(config)
        return Result.new(ok: false, errors: v.errors, warnings: v.warnings, config: v.config, fronts: []) unless v.ok

        c = v.config
        cab = symbolize(cabinet_params || {})
        fronts = build_fronts(cab, c)
        if fronts.empty?
          Result.new(ok: false, errors: ['unable_to_compute_fronts'], warnings: v.warnings, config: c, fronts: [])
        else
          Result.new(ok: true, errors: [], warnings: v.warnings, config: c, fronts: fronts)
        end
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
        %i[gap_mm front_thickness_mm opening_angle_deg perimeter_gap_mm total_width_mm total_height_mm].each do |k|
          next unless c.key?(k) && !c[k].nil?
          errors << "#{k} must be >= 0" unless c[k].is_a?(Numeric) && c[k] >= 0
        end
        if c[:type] == 'single' && c[:split] != 'none'
          warnings << 'split ignored for single door type (scaffold rule)'
        end
        if c[:split] == 'custom_proportional'
          ratios = c[:ratios] || c[:proportions]
          if ratios
            unless ratios.is_a?(Array) && !ratios.empty? && ratios.all? { |x| x.is_a?(Numeric) && x > 0 }
              errors << 'ratios/proportions must be array of positive numbers'
            end
          end
        end
        Result.new(ok: errors.empty?, errors: errors, warnings: warnings, config: c)
      end

      private

      def build_fronts(cab, c)
        count = TYPE_COUNT[c[:type]] || 1
        split = c[:split]
        split = 'none' if c[:type] == 'single'

        total_w = (c[:total_width_mm] || cab[:width_mm]).to_f
        total_h = (c[:total_height_mm] || cab[:height_mm]).to_f
        return [] if total_w <= 0 || total_h <= 0

        perimeter = (c[:perimeter_gap_mm] || 0).to_f
        gap = (c[:gap_mm] || 0).to_f
        avail_w = [total_w - 2 * perimeter, 0].max
        avail_h = [total_h - 2 * perimeter, 0].max

        rows, cols, ratios = layout(count, split, c)
        return [] if rows <= 0 || cols <= 0

        widths = segment_sizes(avail_w, cols, gap, split == 'custom_proportional' && cols > 1 ? ratios : nil)
        heights = segment_sizes(avail_h, rows, gap, split == 'custom_proportional' && rows > 1 ? ratios : nil)

        fronts = []
        idx = 1
        rows.times do |r|
          cols.times do |col|
            break if idx > count
            fronts << front_part(idx, widths[col] || widths.last, heights[r] || heights.last, c, r, col, rows, cols)
            idx += 1
          end
        end
        fronts
      end

      def layout(count, split, c)
        ratios = c[:ratios] || c[:proportions]
        case split
        when 'horizontal'
          [count, 1, ratios]
        when 'vertical'
          [1, count, ratios]
        when 'custom_proportional'
          # default to vertical distribution of count unless rows/cols specified
          rows = (c[:rows] || 1).to_i
          cols = (c[:cols] || count).to_i
          rows = 1 if rows <= 0
          cols = 1 if cols <= 0
          [rows, cols, ratios]
        else # none
          [1, 1, nil]
        end
      end

      def segment_sizes(total, n, gap, ratios)
        return [0.0] if n <= 0
        usable = [total - gap * (n - 1), 0].max
        if ratios.is_a?(Array) && ratios.length == n
          sum = ratios.map(&:to_f).sum
          sum = n.to_f if sum <= 0
          return ratios.map { |r| round3(usable * (r.to_f / sum)) }
        end
        base = usable / n
        Array.new(n, round3(base))
      end

      def front_part(idx, w, h, c, row, col, rows, cols)
        {
          id: nil,
          role: "front_#{idx}",
          name: "front_#{idx}",
          type: 'front',
          front_type: c[:type],
          mounting: c[:mounting],
          row: row,
          col: col,
          rows: rows,
          cols: cols,
          width_mm: [w, 0].max,
          height_mm: [h, 0].max,
          thickness_mm: c[:front_thickness_mm],
          hinge_side: c[:hinge_side],
          material_id: c[:material_id],
          grain_direction: c[:grain_direction],
          edge_banding: { left: nil, right: nil, top: nil, bottom: nil },
          quantity: 1,
          manufacturing_status: 'draft',
          notes: 'prototype_layout'
        }
      end

      def symbolize(h)
        (h || {}).each_with_object({}) { |(k, v), out| out[k.to_sym] = v }
      end

      def round3(v)
        (v.to_f * 1000).round / 1000.0
      end
    end
  end
end
