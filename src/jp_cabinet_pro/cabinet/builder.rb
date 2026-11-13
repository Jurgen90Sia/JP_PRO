# frozen_string_literal: true

module JPCabinetPro
  module Cabinet
    # Builds/rebuilds SketchUp cabinet entities from canonical params/parts when runtime available.
    # Layout is deterministic prototype (not AJ-verified). Safe to call in non-runtime (returns status).
    class Builder
      Result = Struct.new(:ok, :entity, :errors, :created, :replaced, keyword_init: true)

      def initialize(adapter: nil)
        @adapter = adapter
      end

      def create(params:, parts:, target_entities: nil)
        unless runtime?
          return Result.new(ok: false, errors: ['sketchup_runtime_required'], created: false)
        end
        ents = target_entities || @adapter.entities
        return Result.new(ok: false, errors: ['no_active_entities'], created: false) unless ents
        entity = nil
        @adapter.transaction('JP Cabinet PRO: Create Cabinet') do
          entity = ents.add_group
          build_geometry(entity, params, parts)
          finalize_entity(entity, params)
        end
        Result.new(ok: true, entity: entity, errors: [], created: true, replaced: false)
      rescue StandardError => e
        Result.new(ok: false, errors: [e.message], created: false)
      end

      def rebuild(entity:, params:, parts:)
        unless runtime?
          return Result.new(ok: false, errors: ['sketchup_runtime_required'], replaced: false)
        end
        return Result.new(ok: false, errors: ['no_entity'], replaced: false) unless entity
        @adapter.transaction('JP Cabinet PRO: Rebuild Cabinet') do
          entity = @adapter.unique_container!(entity) if @adapter.respond_to?(:unique_container!)
          @adapter.erase_children!(entity) if @adapter.respond_to?(:erase_children!)
          build_geometry(entity, params, parts)
          finalize_entity(entity, params)
        end
        Result.new(ok: true, entity: entity, errors: [], created: false, replaced: true)
      rescue StandardError => e
        Result.new(ok: false, errors: [e.message], replaced: false)
      end

      private

      def runtime?
        @adapter && @adapter.respond_to?(:available?) && @adapter.available? && defined?(::Geom)
      end

      def finalize_entity(entity, params)
        @adapter.mark_cabinet!(entity, params, {}) if @adapter.respond_to?(:mark_cabinet!)
        @adapter.set_tag(entity) if @adapter.respond_to?(:set_tag)
      end

      # Prototype layout: carcass panels + optional plinth/legs/partitions.
      # Coordinate system: origin at cabinet front-left-bottom, X=width, Y=depth, Z=height.
      # Deterministic simplification (not AJ-verified).
      def build_geometry(entity, params, parts)
        ents = @adapter.definition_entities(entity)
        return unless ents
        p = sym(params || {})
        w = f(p[:width_mm], 800.0)
        h = f(p[:height_mm], 720.0)
        d = f(p[:depth_mm], 560.0)
        t = f(p[:panel_thickness_mm], 18.0)
        top_rule = p[:top_construction].to_s
        bottom_rule = p[:bottom_construction].to_s
        back = p[:back_mount_type].to_s
        rear_inset = f(p[:rear_inset_mm], 0.0)
        groove = f(p[:groove_depth_mm], 0.0)
        shelf_count = (p[:shelf_count] || 0).to_i
        partition_count = (p[:partition_count] || 0).to_i
        plinth_h = f(p[:plinth_height_mm], 0.0)
        plinth_setback = f(p[:plinth_setback_mm], 50.0)
        legs_h = f(p[:legs_height_mm], 0.0)
        leg_count = (p[:leg_count] || 0).to_i

        carcass_z = plinth_h
        carcass_h = [h - plinth_h, 0].max

        horiz_w = (top_rule == 'top_over_sides') ? w : [w - 2 * t, 0].max
        bottom_w = (bottom_rule == 'bottom_under_sides') ? w : [w - 2 * t, 0].max
        x_off_top = (top_rule == 'top_over_sides') ? 0.0 : t
        x_off_bottom = (bottom_rule == 'bottom_under_sides') ? 0.0 : t

        # sides
        box(ents, 0.0, 0.0, carcass_z, t, d, carcass_h, 'side_left')
        box(ents, w - t, 0.0, carcass_z, t, d, carcass_h, 'side_right')

        # bottom/top
        z_bottom = carcass_z
        box(ents, x_off_bottom, 0.0, z_bottom, bottom_w, d, t, 'bottom')
        z_top = carcass_z + carcass_h - t
        box(ents, x_off_top, 0.0, z_top, horiz_w, d, t, 'top')

        # back
        bw, bh, bd = back_dims(w, carcass_h, t, top_rule, bottom_rule, rear_inset, groove, back)
        bx = [(w - bw) / 2.0, 0.0].max
        bz = carcass_z + ((bottom_rule == 'bottom_between_sides') ? t : 0.0)
        by = back_y(d, bd, rear_inset, back)
        box(ents, bx, by, bz, bw, bd, bh, 'back') if bw > 0 && bh > 0 && bd > 0

        # shelves
        clear_h = carcass_h
        clear_h -= t if top_rule == 'top_between_sides'
        clear_h -= t if bottom_rule == 'bottom_between_sides'
        z0 = carcass_z + ((bottom_rule == 'bottom_between_sides') ? t : 0.0)
        shelf_d = shelf_depth(d, t, rear_inset, groove, back)
        shelf_w = [w - 2 * t, 0].max
        if shelf_count > 0 && clear_h > 0 && shelf_w > 0 && shelf_d > 0
          step = clear_h / (shelf_count + 1)
          shelf_count.times do |i|
            z = z0 + step * (i + 1) - t / 2.0
            box(ents, t, 0.0, z, shelf_w, shelf_d, t, "shelf_#{i + 1}")
          end
        end

        # partitions (evenly spaced)
        if partition_count > 0 && clear_h > 0 && shelf_d > 0
          step = [w - 2 * t, 0].max / (partition_count + 1)
          partition_count.times do |i|
            x = t + step * (i + 1) - t / 2.0
            box(ents, x, 0.0, z0, t, shelf_d, clear_h, "partition_#{i + 1}")
          end
        end

        # plinth (simple box frame)
        if plinth_h > 0
          pw = [w - 2 * t, 0].max
          pd = [d - plinth_setback, t * 2].max
          box(ents, t, 0.0, 0.0, pw, t, plinth_h, 'plinth_front')
          box(ents, t, [pd - t, 0].max, 0.0, pw, t, plinth_h, 'plinth_back')
          box(ents, t, 0.0, 0.0, t, pd, plinth_h, 'plinth_side_left')
          box(ents, [w - 2 * t, t].max, 0.0, 0.0, t, pd, plinth_h, 'plinth_side_right')
        end

        # legs (simple blocks at corners/centers prototype)
        if legs_h > 0 && leg_count > 0
          positions = leg_positions(w, d, leg_count)
          positions.each_with_index do |(lx, ly), i|
            box(ents, lx, ly, -legs_h, 50.0, 50.0, legs_h, "leg_#{i + 1}")
          end
        end
      end

      def box(ents, x, y, z, w, d, h, name)
        return nil if w <= 0 || d <= 0 || h <= 0
        @adapter.create_box(ents, x: x, y: y, z: z, w: w, h: d, d: h, name: name)
      end

      def back_dims(w, carcass_h, t, top_rule, bottom_rule, rear_inset, groove, back)
        ih = carcass_h
        ih -= t if top_rule == 'top_between_sides'
        ih -= t if bottom_rule == 'bottom_between_sides'
        iw = [w - 2 * t, 0].max
        case back
        when 'surface_mounted_back'
          [w, carcass_h, t]
        when 'grooved_back'
          ins = [groove, t].min
          [iw + 2 * ins, ih + 2 * ins, t]
        when 'hdf_grooved'
          ins = [groove, t].min
          bt = t <= 16 ? 3.0 : 4.0
          [iw + 2 * ins, ih + 2 * ins, bt]
        else
          [iw, ih, t]
        end
      end

      def back_y(d, back_thickness, rear_inset, back)
        case back
        when 'surface_mounted_back'
          [d - back_thickness, 0].max
        when 'recessed_back', 'grooved_back', 'hdf_grooved'
          [d - rear_inset - back_thickness, 0].max
        else
          [d - back_thickness, 0].max
        end
      end

      def shelf_depth(d, t, rear_inset, groove, back)
        depth = case back
                when 'recessed_back' then d - rear_inset - t
                when 'grooved_back', 'hdf_grooved' then d - rear_inset - [groove, t].min
                else d - t
                end
        [depth, 0].max
      end

      def leg_positions(w, d, count)
        inset = 40.0
        corners = [
          [inset, inset],
          [w - inset - 50.0, inset],
          [inset, d - inset - 50.0],
          [w - inset - 50.0, d - inset - 50.0]
        ]
        return corners.take(count) if count <= 4
        extra = (count - 4)
        mids = []
        if extra >= 1
          mids << [(w - 50.0) / 2.0, inset]
        end
        if extra >= 2
          mids << [(w - 50.0) / 2.0, d - inset - 50.0]
        end
        (corners + mids).take(count)
      end

      def sym(h)
        return {} unless h.is_a?(Hash)
        h.each_with_object({}) { |(k, v), out| out[k.to_sym] = v }
      end

      def f(v, d = 0.0)
        v.nil? ? d.to_f : v.to_f
      end
    end
  end
end
