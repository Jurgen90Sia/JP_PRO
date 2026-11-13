# frozen_string_literal: true

module JPCabinetPro
  module Drawers
    # Drawer system engine. Computes drawer front/box layouts (prototype, spec-derived).
    # Adapter-based mechanism catalog; no fabricated manufacturer mounting dimensions.
    # AJ-observed behavior unverified (Phase 0 blocked). Geometry not created in SketchUp.
    class Engine
      MOUNTINGS = %w[overlay inset].freeze
      Result = Struct.new(:ok, :errors, :warnings, :config, :drawers, keyword_init: true)

      def configure(cabinet_params, config)
        v = validate(config)
        return Result.new(ok: false, errors: v.errors, warnings: v.warnings, config: v.config, drawers: []) unless v.ok

        c = v.config
        cab = symbolize(cabinet_params || {})
        drawers = build_drawers(cab, c)
        Result.new(ok: true, errors: [], warnings: v.warnings, config: c, drawers: drawers)
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
        %i[slide_clearance_mm box_depth_mm bottom_thickness_mm side_thickness_mm back_thickness_mm
           total_width_mm total_height_mm gap_mm perimeter_gap_mm].each do |k|
          next unless c.key?(k) && !c[k].nil?
          errors << "#{k} must be >= 0" unless c[k].is_a?(Numeric) && c[k] >= 0
        end
        if c[:catalog_ref].nil?
          warnings << 'no mechanism catalog_ref specified (adapter-based catalog required for verified mounting data)'
        end
        Result.new(ok: errors.empty?, errors: errors, warnings: warnings, config: c)
      end

      private

      def build_drawers(cab, c)
        count = c[:count].to_i
        total_w = (c[:total_width_mm] || cab[:width_mm]).to_f
        total_h = (c[:total_height_mm] || cab[:height_mm]).to_f
        return [] if total_w <= 0 || total_h <= 0 || count <= 0

        perimeter = (c[:perimeter_gap_mm] || 0).to_f
        gap = (c[:gap_mm] || 0).to_f
        slide_clear = (c[:slide_clearance_mm] || 0).to_f
        box_depth = (c[:box_depth_mm] || [cab[:depth_mm].to_f - 50.0, 0].max).to_f

        avail_w = [total_w - 2 * perimeter, 0].max
        avail_h = [total_h - 2 * perimeter - gap * (count - 1), 0].max
        heights = front_heights(avail_h, count, c[:front_heights_mm])

        drawers = []
        count.times do |i|
          fh = heights[i] || heights.last || 0.0
          front = part("drawer_front_#{i + 1}", avail_w, fh, c[:front_thickness_mm], 'drawer_front', c)
          box_w = [avail_w - 2 * slide_clear, 0].max
          box_h = [fh - 2 * gap, 0].max
          box = {
            width_mm: round3(box_w),
            height_mm: round3([box_h, 0].max),
            depth_mm: round3(box_depth),
            side_thickness_mm: c[:side_thickness_mm],
            bottom_thickness_mm: c[:bottom_thickness_mm],
            back_thickness_mm: c[:back_thickness_mm],
            slide_clearance_mm: slide_clear,
            mounting: c[:mounting],
            catalog_ref: c[:catalog_ref]
          }
          parts = [front]
          parts.concat(box_parts(i + 1, box, c))
          drawers << {
            index: i + 1,
            front: front,
            box: box,
            parts: parts
          }
        end
        drawers
      end

      def front_heights(avail_h, count, explicit)
        if explicit.is_a?(Array) && explicit.length == count
          return explicit.map { |h| round3(h.to_f) }
        end
        each = count > 0 ? avail_h / count : 0.0
        Array.new(count, round3(each))
      end

      def box_parts(idx, box, c)
        w = box[:width_mm].to_f
        h = box[:height_mm].to_f
        d = box[:depth_mm].to_f
        st = (box[:side_thickness_mm] || c[:side_thickness_mm] || 16.0).to_f
        bt = (box[:bottom_thickness_mm] || c[:bottom_thickness_mm] || 16.0).to_f
        rt = (box[:back_thickness_mm] || c[:back_thickness_mm] || 16.0).to_f
        [
          part("drawer_#{idx}_side_left", st, h, d, 'drawer_side', c),
          part("drawer_#{idx}_side_right", st, h, d, 'drawer_side', c),
          part("drawer_#{idx}_back", [w - 2 * st, 0].max, h, rt, 'drawer_back', c),
          part("drawer_#{idx}_bottom", [w - 2 * st, 0].max, bt, d, 'drawer_bottom', c)
        ]
      end

      def part(role, w, h, t, type, c)
        {
          id: nil,
          role: role,
          name: role,
          type: type,
          width_mm: round3([w, 0].max),
          height_mm: round3([h, 0].max),
          thickness_mm: t,
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
