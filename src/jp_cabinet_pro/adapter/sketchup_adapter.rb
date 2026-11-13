# frozen_string_literal: true

require 'json'

module JPCabinetPro
  module Adapter
    # Isolates SketchUp API calls. All destructive operations must be transaction-safe.
    # Methods are runtime-guarded so pure-logic tests can run without SketchUp.
    class SketchupAdapter
      DICT = 'jp_cabinet_pro'.freeze
      TAG = 'JP Cabinet PRO'.freeze

      def initialize(model: nil)
        @model = model || (defined?(::Sketchup) ? ::Sketchup.active_model : nil)
      end

      attr_reader :model

      def available?
        !!(defined?(::Sketchup) && @model)
      end

      def entities
        return nil unless available?
        @model.active_entities
      end

      def selection
        return nil unless available?
        @model.selection
      end

      def transaction(name)
        unless available?
          return yield if block_given?
        end
        @model.start_operation(name, true)
        result = yield
        @model.commit_operation
        result
      rescue StandardError => e
        begin
          @model.abort_operation if @model && @model.respond_to?(:abort_operation)
        rescue StandardError
          # ignore abort failures
        end
        raise e
      end

      # --- Attributes / identity ---
      def set_attr(entity, key, value)
        return false unless entity && entity.respond_to?(:set_attribute)
        entity.set_attribute(DICT, key.to_s, value)
        true
      rescue StandardError
        false
      end

      def get_attr(entity, key, default = nil)
        return default unless entity || !entity.respond_to?(:get_attribute)
        v = entity.get_attribute(DICT, key.to_s)
        v.nil? ? default : v
      rescue StandardError
        default
      end

      def cabinet?(entity)
        get_attr(entity, 'type') == 'cabinet'
      end

      def mark_cabinet!(entity, params = {}, meta = {})
        return false unless entity
        set_attr(entity, 'type', 'cabinet')
        set_attr(entity, 'version', JPCabinetPro::EXTENSION_VERSION) if defined?(JPCabinetPro::EXTENSION_VERSION)
        begin
          set_attr(entity, 'params_json', JSON.generate(params || {}))
        rescue StandardError
          nil
        end
        (meta || {}).each { |k, v| set_attr(entity, k, v) }
        name = build_name(params)
        if entity.respond_to?(:name=)
          begin entity.name = name rescue StandardError; end
        end
        true
      end

      def read_params(entity)
        raw = get_attr(entity, 'params_json')
        return nil if raw.nil? || raw.to_s.empty?
        JSON.parse(raw.to_s, symbolize_names: true)
      rescue StandardError
        nil
      end

      # --- Entity helpers ---
      def group?(entity)
        defined?(::Sketchup::Group) && entity.is_a?(::Sketchup::Group)
      end

      def component_instance?(entity)
        defined?(::Sketchup::ComponentInstance) && entity.is_a?(::Sketchup::ComponentInstance)
      end

      def container?(entity)
        group?(entity) || component_instance?(entity)
      end

      def definition_entities(entity)
        return entity.entities if group?(entity)
        return entity.definition.entities if component_instance?(entity) && entity.respond_to?(:definition)
        nil
      end

      def erase_children!(entity)
        ents = definition_entities(entity)
        return 0 unless ents && ents.respond_to?(:to_a)
        children = ents.to_a
        if ents.respond_to?(:erase_entities)
          ents.erase_entities(children) unless children.empty?
        else
          children.each { |c| ents.erase(c) rescue nil }
        end
        children.length
      rescue StandardError
        0
      end

      def unique_container!(entity)
        return entity unless component_instance?(entity)
        if entity.respond_to?(:definition) && entity.definition && entity.definition.respond_to?(:instances)
          begin
            entity.make_unique if entity.definition.instances.length > 1 && entity.respond_to?(:make_unique)
          rescue StandardError
            # ignore
          end
        end
        entity
      end

      def ensure_tag(name = TAG)
        return nil unless available?
        tags = @model.layers rescue nil
        return nil unless tags
        tag = tags[name] rescue nil
        unless tag
          begin tag = tags.add(name) rescue nil; end
        end
        tag
      end

      def set_tag(entity, name = TAG)
        tag = ensure_tag(name)
        return false unless tag && entity
        begin
          entity.layer = tag if entity.respond_to?(:layer=)
          entity.tag = tag if entity.respond_to?(:tag=)
          true
        rescue StandardError
          false
        end
      end

      def mm(val)
        if defined?(::Sketchup) && val.respond_to?(:mm)
          val.to_f.mm
        else
          val.to_f
        end
      end

      def create_box(parent_entities, x:, y:, z:, w:, h:, d:, name: nil)
        return nil unless parent_entities && defined?(::Geom)
        g = parent_entities.add_group
        ents = g.entities
        pts = [
          Geom::Point3d.new(mm(x), mm(y), mm(z)),
          Geom::Point3d.new(mm(x + w), mm(y), mm(z)),
          Geom::Point3d.new(mm(x + w), mm(y + h), mm(z)),
          Geom::Point3d.new(mm(x), mm(y + h), mm(z))
        ]
        face = ents.add_face(pts)
        face.pushpull(mm(d)) if face
        g.name = name.to_s if name && g.respond_to?(:name=)
        g
      rescue StandardError
        nil
      end

      def build_name(params)
        p = symbolize(params || {})
        w = p[:width_mm] || p['width_mm']
        h = p[:height_mm] || p['height_mm']
        d = p[:depth_mm] || p['depth_mm']
        "JP Cabinet #{w}x#{h}x#{d}"
      end

      def symbolize(h)
        return {} unless h.is_a?(Hash)
        h.each_with_object({}) { |(k, v), out| out[k.to_sym] = v }
      end
    end
  end
end
