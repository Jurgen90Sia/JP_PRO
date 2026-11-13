# frozen_string_literal: true

module JPCabinetPro
  module Selection
    # Selection and geometry extraction.
    # Runtime-dependent paths are guarded; pure helpers are testable without SketchUp.
    class Extractor
      Result = Struct.new(:ok, :entity, :entities, :parts, :error, keyword_init: true)

      def initialize(adapter:)
        @adapter = adapter
      end

      # Finds the best cabinet candidate from current selection (or provided enumerable).
      def selected_cabinet(selection = nil)
        sel = selection || (@adapter.respond_to?(:selection) ? @adapter.selection : nil)
        return Result.new(ok: false, error: 'sketchup_runtime_required', entities: []) unless sel
        cands = []
        Array(sel.respond_to?(:to_a) ? sel.to_a : sel).each do |e|
          found = find_cabinet_in(e)
          cands.concat(found) if found
        end
        cands.uniq!
        if cands.empty?
          Result.new(ok: false, error: 'no_cabinet_selected', entities: [])
        else
          Result.new(ok: true, entity: cands.first, entities: cands)
        end
      rescue StandardError => e
        Result.new(ok: false, error: e.message, entities: [])
      end

      # Recursive search: entity itself or descendants marked as cabinet.
      def find_cabinet_in(entity, depth = 0, out = [])
        return out if entity.nil? || depth > 30
        if @adapter.respond_to?(:cabinet?) && @adapter.cabinet?(entity)
          out << entity
        end
        # also accept by attribute dict name fallback
        if out.empty? && @adapter.respond_to?(:get_attr)
          t = @adapter.get_attr(entity, 'type')
          out << entity if t == 'cabinet'
        end
        if @adapter.respond_to?(:definition_entities)
          ents = @adapter.definition_entities(entity)
          if ents && ents.respond_to?(:each)
            ents.each { |child| find_cabinet_in(child, depth + 1, out) }
          end
        end
        out
      end

      # Extract bounding-box/instance info from an entity tree without double-counting definitions.
      # Returns metadata only (safe); does not mutate.
      def extract_parts(entity)
        return Result.new(ok: false, error: 'sketchup_runtime_required', parts: []) unless entity
        rows = []
        visited_defs = {}
        walk(entity, GeomIdentity.identity, rows, visited_defs, 0)
        Result.new(ok: true, parts: rows)
      rescue StandardError => e
        Result.new(ok: false, error: e.message, parts: [])
      end

      private

      def walk(entity, transform, rows, visited_defs, depth)
        return if depth > 40 || entity.nil?
        if @adapter.respond_to?(:component_instance?) && @adapter.component_instance?(entity)
          defn = entity.respond_to?(:definition) ? entity.definition : nil
          key = definition_key(defn)
          tr = transform_product(transform, entity.respond_to?(:transformation) ? entity.transformation : transform)
          rows << part_row(entity, tr, 'component_instance')
          # traverse definition entities once per definition id to describe canonical parts,
          # but still record instances separately for counts.
          if defn && key && !visited_defs[key]
            visited_defs[key] = true
            if defn.respond_to?(:entities)
              defn.entities.each { |ch| walk(ch, tr, rows, visited_defs, depth + 1) }
            end
          end
        elsif @adapter.respond_to?(:group?) && @adapter.group?(entity)
          tr = transform_product(transform, entity.respond_to?(:transformation) ? entity.transformation : transform)
          rows << part_row(entity, tr, 'group')
          ents = entity.respond_to?(:entities) ? entity.entities : nil
          if ents
            ents.each { |ch| walk(ch, tr, rows, visited_defs, depth + 1) }
          end
        elsif face_or_edge?(entity)
          rows << part_row(entity, transform, 'primitive')
        end
      end

      def definition_key(defn)
        return nil unless defn
        if defn.respond_to?(:guid)
          "guid:#{defn.guid}"
        elsif defn.respond_to?(:entityID)
          "eid:#{defn.entityID}"
        else
          defn.object_id.to_s
        end
      rescue StandardError
        nil
      end

      def transform_product(a, b)
        if a.respond_to?(:*) && b
          a * b
        else
          b || a
        end
      rescue StandardError
        b || a
      end

      def part_row(entity, transform, kind)
        bounds = safe_bounds(entity, transform)
        {
          kind: kind,
          name: (entity.respond_to?(:name) ? entity.name : nil),
          persistent_id: (entity.respond_to?(:persistent_id) ? entity.persistent_id : (entity.respond_to?(:entityID) ? entity.entityID : nil)),
          bounds_mm: bounds,
          cabinet_type: (@adapter.respond_to?(:get_attr) ? @adapter.get_attr(entity, 'type') : nil)
        }
      end

      def safe_bounds(entity, transform)
        return nil unless entity && entity.respond_to?(:bounds)
        b = entity.bounds
        # bounds in local space; transform corners for rough global mm if Geom available
        min = b.min
        max = b.max
        if defined?(::Geom) && transform && min && max
          corners = [
            Geom::Point3d.new(min.x, min.y, min.z),
            Geom::Point3d.new(max.x, max.y, max.z)
          ].map { |p| transform_point(transform, p) }
          gmin = corners[0]
          gmax = corners[1]
          to_mm_box(gmin, gmax)
        else
          to_mm_box(min, max)
        end
      rescue StandardError
        nil
      end

      def transform_point(tr, pt)
        tr.respond_to?(:*) ? (tr * pt) : pt
      rescue StandardError
        pt
      end

      def to_mm_box(a, b)
        return nil unless a && b
        ax = length_to_mm(a.x); ay = length_to_mm(a.y); az = length_to_mm(a.z)
        bx = length_to_mm(b.x); by = length_to_mm(b.y); bz = length_to_mm(b.z)
        {
          min: [ [ax,bx].min, [ay,by].min, [az,bz].min ],
          max: [ [ax,bx].max, [ay,by].max, [az,bz].max ]
        }
      end

      def length_to_mm(v)
        if v.respond_to?(:to_mm)
          v.to_mm.to_f
        elsif defined?(::Sketchup) && v.respond_to?(:to_f)
          # SketchUp Length is inches; to_mm safest, fallback convert
          v.to_f * 25.4
        else
          v.to_f
        end
      rescue StandardError
        v.to_f
      end

      def face_or_edge?(entity)
        (defined?(::Sketchup::Face) && entity.is_a?(::Sketchup::Face)) ||
          (defined?(::Sketchup::Edge) && entity.is_a?(::Sketchup::Edge))
      end

      module GeomIdentity
        module_function
        def identity
          if defined?(::Geom::Transformation)
            Geom::Transformation.new
          else
            nil
          end
        end
      end
    end
  end
end
