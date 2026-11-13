# frozen_string_literal: true

require_relative '../doors/front_engine'
require_relative '../drawers/engine'
require_relative '../hardware/engine'

module JPCabinetPro
  module Cabinet
    # Cabinet construction/rebuild engine.
    # Geometry mutation in SketchUp must be transaction-safe via Adapter with rollback on failure.
    # Computes a deterministic part set based on construction rules (prototype).
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
        w = params[:width_mm].to_f
        h = params[:height_mm].to_f
        d = params[:depth_mm].to_f
        t = params[:panel_thickness_mm].to_f
        shelves = params[:shelf_count].to_i
        rear_inset = params[:rear_inset_mm].to_f
        groove = params[:groove_depth_mm].to_f
        back = params[:back_mount_type].to_s
        top_rule = params[:top_construction].to_s
        bottom_rule = params[:bottom_construction].to_s

        parts = []
        parts << part('side_left',  t, h, d, notes: 'side panel')
        parts << part('side_right', t, h, d, notes: 'side panel')

        horiz_w = (top_rule == 'top_over_sides') ? w : [w - 2 * t, 0].max
        bottom_w = (bottom_rule == 'bottom_under_sides') ? w : [w - 2 * t, 0].max
        parts << part('top',    horiz_w, t, d, notes: top_rule)
        parts << part('bottom', bottom_w, t, d, notes: bottom_rule)

        bw, bh, bd = back_dimensions(w, h, d, t, rear_inset, groove, back)
        parts << part('back', bw, bh, bd, notes: back)

        shelf_d = shelf_depth(d, t, rear_inset, groove, back)
        shelf_w = [w - 2 * t, 0].max
        shelves.times do |i|
          parts << part("shelf_#{i + 1}", shelf_w, t, shelf_d, notes: 'adjustable shelf placeholder')
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
        {
          top: params[:top_construction],
          bottom: params[:bottom_construction],
          back: params[:back_mount_type]
        }
      end

      def back_dimensions(w, h, d, t, rear_inset, groove, back)
        case back
        when 'full_back'
          [[w - 2 * t, 0].max, [h - 2 * t, 0].max, t]
        when 'recessed_back'
          [[w - 2 * t, 0].max, [h - 2 * t, 0].max, t]
        when 'grooved_back'
          [[w - 2 * t + 2 * [groove, t].min, 0].max, [h - 2 * t + 2 * [groove, t].min, 0].max, t]
        when 'surface_mounted_back'
          [w, h, t]
        else
          [[w - 2 * t, 0].max, [h - 2 * t, 0].max, t]
        end
      end

      def shelf_depth(d, t, rear_inset, groove, back)
        depth = case back
                when 'recessed_back' then d - rear_inset - t
                when 'grooved_back' then d - rear_inset - [groove, t].min
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
    end
  end
end
