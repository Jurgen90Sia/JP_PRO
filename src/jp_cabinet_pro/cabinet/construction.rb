# frozen_string_literal: true

require_relative '../doors/front_engine'
require_relative '../drawers/engine'
require_relative '../hardware/engine'

module JPCabinetPro
  module Cabinet
    # Cabinet construction/rebuild engine.
    # Computes a deterministic part set based on construction rules (prototype, AJ-unverified).
    # SketchUp geometry mutation is performed by Builder in runtime transactions.
    class Construction
      def initialize(adapter:)
        @adapter = adapter
        @fronts = JPCabinetPro::Doors::FrontEngine.new
        @drawers = JPCabinetPro::Drawers::Engine.new
        @hardware = JPCabinetPro::Hardware::Engine.new
      end

      def rebuild(params:, existing: nil)
        parts = build_parts(params)
        fronts = build_fronts(params)
        drawers = build_drawers(params)
        hardware = normalize_hardware(params)
        {
          ok: true,
          parts: parts,
          fronts: fronts,
          drawers: drawers,
          hardware: hardware,
          replaced: !existing.nil?,
          construction: construction_summary(params)
        }
      rescue StandardError => e
        { ok: false, error: e.message }
      end

      def build_parts(params)
        p = sym(params)
        w = p[:width_mm].to_f
        h = p[:height_mm].to_f
        d = p[:depth_mm].to_f
        t = p[:panel_thickness_mm].to_f
        shelves = p[:shelf_count].to_i
        partitions = p[:partition_count].to_i
        rear_inset = p[:rear_inset_mm].to_f
        groove = p[:groove_depth_mm].to_f
        back = p[:back_mount_type].to_s
        top_rule = p[:top_construction].to_s
        bottom_rule = p[:bottom_construction].to_s
        plinth_h = p[:plinth_height_mm].to_f
        plinth_setback = p[:plinth_setback_mm].to_f
        legs_h = p[:legs_height_mm].to_f
        leg_count = p[:leg_count].to_i

        parts = []
        parts << part('side_left',  t, h, d, notes: 'side panel')
        parts << part('side_right', t, h, d, notes: 'side panel')

        horiz_w = (top_rule == 'top_over_sides') ? w : [w - 2 * t, 0].max
        bottom_w = (bottom_rule == 'bottom_under_sides') ? w : [w - 2 * t, 0].max
        parts << part('top',    horiz_w, t, d, notes: top_rule)
        parts << part('bottom', bottom_w, t, d, notes: bottom_rule)

        bw, bh, bd, bnote = back_dimensions(w, h, d, t, rear_inset, groove, back, top_rule, bottom_rule)
        parts << part('back', bw, bh, bd, notes: bnote)

        shelf_d = shelf_depth(d, t, rear_inset, groove, back)
        shelf_w = [w - 2 * t, 0].max
        shelves.times do |i|
          parts << part("shelf_#{i + 1}", shelf_w, t, shelf_d, notes: 'adjustable shelf')
        end

        # partitions: vertical dividers between sides (same clear depth/height as opening)
        if partitions > 0
          clear_h = h
          clear_h -= t if top_rule == 'top_between_sides'
          clear_h -= t if bottom_rule == 'bottom_between_sides'
          partitions.times do |i|
            parts << part("partition_#{i + 1}", t, [clear_h, 0].max, shelf_d, notes: 'vertical partition')
          end
        end

        # plinth: front/rear stretchers as prototype parts (deterministic)
        if plinth_h > 0
          pw = [w - 2 * t, 0].max
          pd = [d - plinth_setback, t].max
          parts << part('plinth_front', pw, plinth_h, t, notes: 'plinth')
          parts << part('plinth_back',  pw, plinth_h, t, notes: 'plinth')
          parts << part('plinth_side_left',  t, plinth_h, [pd - 2 * t, t].max, notes: 'plinth')
          parts << part('plinth_side_right', t, plinth_h, [pd - 2 * t, t].max, notes: 'plinth')
        end

        # legs: represented as hardware-like parts for BOM/calc (prototype)
        if legs_h > 0 && leg_count > 0
          leg_count.times do |i|
            parts << part("leg_#{i + 1}", 50.0, legs_h, 50.0, notes: 'adjustable leg (prototype)')
          end
        end

        parts
      end

      def build_fronts(params)
        cfg = params[:fronts] || params[:doors]
        return [] unless cfg
        r = @fronts.configure(params, cfg)
        r.ok ? r.fronts : []
      end

      def build_drawers(params)
        cfg = params[:drawers]
        return [] unless cfg
        r = @drawers.configure(params, cfg)
        r.ok ? r.drawers : []
      end

      def normalize_hardware(params)
        items = params[:hardware] || []
        @hardware.bom_lines(items)
      end

      private

      def construction_summary(params)
        p = sym(params)
        {
          top: p[:top_construction],
          bottom: p[:bottom_construction],
          back: p[:back_mount_type],
          plinth_height_mm: p[:plinth_height_mm],
          legs_height_mm: p[:legs_height_mm],
          partitions: p[:partition_count]
        }
      end

      def back_dimensions(w, h, d, t, rear_inset, groove, back, top_rule, bottom_rule)
        ih = h
        ih -= t if top_rule == 'top_between_sides'
        ih -= t if bottom_rule == 'bottom_between_sides'
        iw = [w - 2 * t, 0].max
        case back
        when 'full_back', 'recessed_back'
          [iw, [ih, 0].max, t, back]
        when 'grooved_back'
          ins = [groove, t].min
          [[iw + 2 * ins, 0].max, [ih + 2 * ins, 0].max, t, 'grooved_back']
        when 'hdf_grooved'
          ins = [groove, t].min
          bt = [pick_hdf_thickness(t), 3.0].max
          [[iw + 2 * ins, 0].max, [ih + 2 * ins, 0].max, bt, 'hdf_grooved_back']
        when 'surface_mounted_back'
          [w, h, t, back]
        else
          [iw, [ih, 0].max, t, back]
        end
      end

      def pick_hdf_thickness(panel_t)
        # common HDF backs: 3-4mm; prototype heuristic only
        panel_t <= 16 ? 3.0 : 4.0
      end

      def shelf_depth(d, t, rear_inset, groove, back)
        depth = case back
                when 'recessed_back' then d - rear_inset - t
                when 'grooved_back', 'hdf_grooved' then d - rear_inset - [groove, t].min
                when 'full_back', 'surface_mounted_back' then d - t
                else d - rear_inset
                end
        [depth, 0].max
      end

      def part(role, w, h, t, notes: nil)
        {
          id: nil,
          role: role,
          name: role,
          width_mm: w,
          height_mm: h,
          thickness_mm: t,
          material_id: nil,
          grain_direction: nil,
          edge_banding: { left: nil, right: nil, top: nil, bottom: nil },
          quantity: 1,
          manufacturing_status: 'draft',
          source_geometry_ref: nil,
          revision: nil,
          notes: notes
        }
      end

      def sym(h)
        return {} unless h.is_a?(Hash)
        h.each_with_object({}) { |(k, v), out| out[k.to_sym] = v }
      end
    end
  end
end
