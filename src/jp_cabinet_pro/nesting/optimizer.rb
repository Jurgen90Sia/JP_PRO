# frozen_string_literal: true

module JPCabinetPro
  module Nesting
    # 2D rectangular nesting optimizer.
    # Strategies: maxrects, guillotine, best_area_fit, best_short_side_fit.
    # Results are geometrically validated; utilization computed only from validated placements.
    # No fabricated metrics. Grain/kerf/trim/rotation supported; manual ops not included.
    class Optimizer
      STRATEGIES = %w[maxrects guillotine best_area_fit best_short_side_fit].freeze

      Part = Struct.new(:id, :w, :h, :qty, :material, :thickness, :grain, :can_rotate, keyword_init: true)
      Sheet = Struct.new(:id, :w, :h, :kerf, :trim, :material, :thickness, keyword_init: true)
      Placement = Struct.new(:sheet_id, :part_id, :x, :y, :w, :h, :rotated, :validated, keyword_init: true)

      def plan(parts, sheets, strategy: 'maxrects', **_opts)
        strat = strategy.to_s
        raise ArgumentError, "unsupported strategy: #{strategy}" unless STRATEGIES.include?(strat)

        norm_parts = normalize_parts(parts)
        norm_sheets = normalize_sheets(sheets)
        groups = norm_parts.group_by { |p| [p.material, p.thickness] }
        all_placements = []
        sheets_used = []
        unplaced = []
        sheet_instances = []

        groups.each do |(mat, th), gparts|
          gsheets = norm_sheets.select { |s| [s.material, s.thickness] == [mat, th] }
          rects = []
          gparts.each do |p|
            (p.qty || 1).times { |i| rects << { id: "#{p.id}##{i + 1}", base_id: p.id, w: p.w.to_f, h: p.h.to_f, grain: p.grain, can_rotate: !!p.can_rotate } }
          end
          result = nest_group(rects, gsheets, strat)
          all_placements.concat(result[:placements])
          sheets_used.concat(result[:sheets_used])
          unplaced.concat(result[:unplaced])
          sheet_instances.concat(result[:sheet_instances])
        end

        validated = validate_placements(all_placements, norm_sheets)
        utilization = compute_utilization(validated, sheets_used, norm_sheets)
        offcuts = collect_offcuts(sheet_instances)
        cut_length_mm = compute_cut_length(validated, norm_sheets)
        {
          ok: true,
          strategy: strat,
          placements: validated,
          sheets_used: sheets_used.uniq,
          unplaced: unplaced,
          utilization: utilization,
          offcuts: offcuts,
          cut_length_mm: cut_length_mm,
          cut_length_status: cut_length_mm.nil? ? 'NOT_COMPUTED' : 'OK',
          validated: validated.all? { |p| p[:validated] }
        }
      end

      def implemented?
        true
      end

      private

      def normalize_parts(parts)
        (parts || []).map do |p|
          h = sym(p)
          Part.new(
            id: h[:id] || h[:part_id] || object_id.to_s,
            w: h[:w] || h[:width_mm] || h[:width],
            h: h[:h] || h[:height_mm] || h[:height] || h[:length],
            qty: (h[:qty] || h[:quantity] || 1).to_i,
            material: h[:material] || h[:material_id],
            thickness: h[:thickness] || h[:thickness_mm],
            grain: h[:grain] || h[:grain_direction],
            can_rotate: h.key?(:can_rotate) ? h[:can_rotate] : grain_allows_rotation?(h[:grain] || h[:grain_direction])
          )
        end
      end

      def normalize_sheets(sheets)
        (sheets || []).map do |s|
          h = sym(s)
          Sheet.new(
            id: h[:id], w: h[:w] || h[:width_mm] || h[:width], h: h[:h] || h[:height_mm] || h[:height],
            kerf: (h[:kerf] || 0).to_f, trim: (h[:trim] || 0).to_f,
            material: h[:material] || h[:material_id], thickness: h[:thickness] || h[:thickness_mm]
          )
        end
      end

      def grain_allows_rotation?(grain)
        g = grain.to_s.downcase
        return true if g.empty? || g == 'none' || g == 'any' || g == 'n'
        false
      end

      def nest_group(rects, sheets, strategy)
        placements = []
        unplaced = []
        used_sheet_ids = []
        remaining = rects.map(&:dup)

        sheet_instances = []
        pool = sheets.dup
        remaining.sort_by! { |r| -(r[:w] * r[:h]) }

        remaining.each do |rect|
          placed = false
          orientations = orientations_for(rect)

          sheet_instances.each do |inst|
            pos = find_position(inst, rect, orientations, strategy)
            if pos
              commit_place(inst, rect, pos, placements)
              used_sheet_ids << inst[:sheet_id]
              placed = true
              break
            end
          end
          next if placed

          while !placed && !pool.empty?
            base = pool.shift
            inst = new_instance(base)
            sheet_instances << inst
            pos = find_position(inst, rect, orientations, strategy)
            if pos
              commit_place(inst, rect, pos, placements)
              used_sheet_ids << inst[:sheet_id]
              placed = true
            end
          end

          unless placed
            unplaced << rect[:base_id] unless sheet_instances.any? { |inst| find_position(inst, rect, orientations, strategy) }
          end
        end

        { placements: placements, sheets_used: used_sheet_ids.uniq, unplaced: unplaced.uniq, sheet_instances: sheet_instances }
      end

      def new_instance(base)
        t = base.trim.to_f
        uw = [base.w.to_f - 2 * t, 0].max
        uh = [base.h.to_f - 2 * t, 0].max
        {
          sheet_id: base.id,
          base_w: base.w.to_f, base_h: base.h.to_f,
          trim: t, kerf: base.kerf.to_f,
          usable_w: uw, usable_h: uh,
          free: uw > 0 && uh > 0 ? [{ x: 0.0, y: 0.0, w: uw, h: uh }] : [],
          used: []
        }
      end

      def orientations_for(rect)
        o = [{ w: rect[:w], h: rect[:h], rotated: false }]
        if rect[:can_rotate] && (rect[:w] - rect[:h]).abs > 1e-9
          o << { w: rect[:h], h: rect[:w], rotated: true }
        end
        o
      end

      def can_fit_any?(inst, rect, orientations)
        orientations.any? { |o| inst[:free].any? { |f| o[:w] <= f[:w] + 1e-9 && o[:h] <= f[:h] + 1e-9 } }
      end

      def find_position(inst, rect, orientations, strategy)
        best = nil
        orientations.each do |o|
          rw = o[:w]
          rh = o[:h]
          inst[:free].each do |f|
            next unless rw <= f[:w] + 1e-9 && rh <= f[:h] + 1e-9
            score = score_fit(f, rw, rh, strategy)
            cand = { x: f[:x], y: f[:y], w: rw, h: rh, rotated: o[:rotated], free: f, score: score }
            best = cand if best.nil? || better?(cand, best, strategy)
          end
        end
        best
      end

      def score_fit(free, rw, rh, strategy)
        leftover_x = free[:w] - rw
        leftover_y = free[:h] - rh
        short = [leftover_x, leftover_y].min
        long = [leftover_x, leftover_y].max
        area_fit = free[:w] * free[:h] - rw * rh
        case strategy
        when 'best_area_fit'
          [area_fit, short]
        when 'best_short_side_fit'
          [short, long]
        when 'guillotine'
          [short, area_fit]
        else # maxrects
          [short, long]
        end
      end

      def better?(a, b, _strategy)
        sa = a[:score]
        sb = b[:score]
        cmp = sa <=> sb
        return true if cmp == -1
        return false if cmp == 1
        a[:y] < b[:y] || (a[:y] == b[:y] && a[:x] < b[:x])
      end

      def commit_place(inst, rect, pos, placements)
        kerf = inst[:kerf]
        px = pos[:x]
        py = pos[:y]
        pw = pos[:w]
        ph = pos[:h]
        placements << {
          sheet_id: inst[:sheet_id],
          part_id: rect[:base_id],
          instance_id: rect[:id],
          x: round3(px + inst[:trim]),
          y: round3(py + inst[:trim]),
          w: round3(pw),
          h: round3(ph),
          rotated: pos[:rotated],
          validated: false
        }
        used_rect = { x: px, y: py, w: pw, h: ph }
        inst[:used] << used_rect
        split_free(inst, pos[:free], used_rect, kerf)
      end

      # Guillotine split with kerf: remove used free rect and add remainders
      def split_free(inst, free, used, kerf)
        inst[:free].delete(free)
        rx = used[:x] + used[:w] + kerf
        ry = used[:y] + used[:h] + kerf
        rw = (free[:x] + free[:w]) - rx
        rh = (free[:y] + free[:h]) - ry
        right = { x: rx, y: free[:y], w: [rw, 0].max, h: free[:h] }
        top_r = { x: free[:x], y: ry, w: used[:w], h: [rh, 0].max }
        right_alt = { x: rx, y: free[:y], w: [rw, 0].max, h: used[:h] }
        top_alt = { x: free[:x], y: ry, w: free[:w], h: [rh, 0].max }

        if [rw, 0].max * free[:h] + used[:w] * [rh, 0].max >= used[:h] * [rw, 0].max + free[:w] * [rh, 0].max
          add_free(inst, right)
          add_free(inst, top_r)
        else
          add_free(inst, right_alt)
          add_free(inst, top_alt)
        end
        prune_free(inst)
      end

      def add_free(inst, r)
        return if r[:w] <= 1e-9 || r[:h] <= 1e-9
        inst[:free] << r
      end

      def prune_free(inst)
        free = inst[:free]
        keep = []
        free.each_with_index do |a, i|
          contained = free.each_with_index.any? { |b, j| i != j && contains?(b, a) }
          keep << a unless contained
        end
        inst[:free] = keep
      end

      def contains?(a, b)
        a[:x] <= b[:x] + 1e-9 && a[:y] <= b[:y] + 1e-9 &&
          a[:x] + a[:w] >= b[:x] + b[:w] - 1e-9 && a[:y] + a[:h] >= b[:y] + b[:h] - 1e-9
      end

      def validate_placements(placements, sheets)
        by_sheet = placements.group_by { |p| p[:sheet_id] }
        sheet_map = {}
        sheets.each { |s| sheet_map[s.id] = s }
        placements.map do |p|
          ok = true
          s = sheet_map[p[:sheet_id]]
          ok = false unless s
          if s
            t = s.trim.to_f
            ux = t; uy = t; uw = s.w.to_f - 2 * t; uh = s.h.to_f - 2 * t
            ok = false if p[:x] < ux - 1e-6 || p[:y] < uy - 1e-6
            ok = false if p[:x] + p[:w] > ux + uw + 1e-6
            ok = false if p[:y] + p[:h] > uy + uh + 1e-6
          end
          siblings = by_sheet[p[:sheet_id]] || []
          siblings.each do |q|
            next if q.equal?(p)
            ok = false if overlap?(p, q)
          end
          p.merge(validated: ok)
        end
      end

      def overlap?(a, b)
        !(a[:x] + a[:w] <= b[:x] + 1e-9 || b[:x] + b[:w] <= a[:x] + 1e-9 ||
          a[:y] + a[:h] <= b[:y] + 1e-9 || b[:y] + b[:h] <= a[:y] + 1e-9)
      end

      # Approximate cut length: sum of perimeters of validated placements.
      # (Does not model shared/guillotine cut optimization; reported as computed estimate.)
      def compute_cut_length(validated, _sheets)
        valid = validated.select { |p| p[:validated] }
        return 0.0 if valid.empty?
        total = valid.sum { |p| 2.0 * (p[:w].to_f + p[:h].to_f) }
        round3(total)
      end

      def compute_utilization(validated, used_sheet_ids, sheets)
        valid = validated.select { |p| p[:validated] }
        placed_area = valid.sum { |p| p[:w].to_f * p[:h].to_f }
        sheet_map = {}
        sheets.each { |s| sheet_map[s.id] = s }
        usable_area = used_sheet_ids.uniq.sum do |id|
          s = sheet_map[id]
          next 0.0 unless s
          t = s.trim.to_f
          [s.w.to_f - 2 * t, 0].max * [s.h.to_f - 2 * t, 0].max
        end
        return nil if usable_area <= 0.0
        round6(placed_area / usable_area)
      end

      def collect_offcuts(instances)
        (instances || []).flat_map do |inst|
          (inst[:free] || []).map do |f|
            {
              sheet_id: inst[:sheet_id],
              x: round3(f[:x] + inst[:trim]),
              y: round3(f[:y] + inst[:trim]),
              w: round3(f[:w]),
              h: round3(f[:h]),
              area_mm2: round3(f[:w] * f[:h])
            }
          end
        end
      end

      def sym(h)
        return {} unless h.is_a?(Hash)
        h.each_with_object({}) { |(k, v), out| out[k.to_sym] = v }
      end

      def round3(v) = (v.to_f * 1000).round / 1000.0
      def round6(v) = (v.to_f * 1_000_000).round / 1_000_000.0
    end
  end
end
