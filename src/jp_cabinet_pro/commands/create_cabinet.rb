# frozen_string_literal: true

require_relative '../parametric/dimensions'
require_relative '../cabinet/construction'
require_relative '../cabinet/builder'
require_relative '../persistence/store'

module JPCabinetPro
  module Commands
    # Creates a new cabinet in the active SketchUp model when runtime is available.
    # Falls back to returning computed parts/params in non-runtime environments.
    class CreateCabinet
      Result = Struct.new(:ok, :errors, :params, :parts, :entity_status, keyword_init: true)

      def initialize(adapter: nil)
        @adapter = adapter
        @construction = JPCabinetPro::Cabinet::Construction.new(adapter: adapter)
        @builder = JPCabinetPro::Cabinet::Builder.new(adapter: adapter)
      end

      def execute(input = {})
        validated = JPCabinetPro::Parametric::Dimensions.validate(input)
        return Result.new(ok: false, errors: validated.errors, params: validated.values) unless validated.ok

        parts = @construction.build_parts(validated.values)
        entity_status = { created: false, runtime: runtime? }
        if runtime?
          br = @builder.create(params: validated.values, parts: parts)
          entity_status.merge!(ok: br.ok, created: br.created, errors: br.errors)
          persist_to_entity(br.entity, validated.values) if br.ok && br.entity
        end
        Result.new(ok: true, errors: [], params: validated.values, parts: parts, entity_status: entity_status)
      rescue StandardError => e
        Result.new(ok: false, errors: [e.message])
      end

      private

      def runtime?
        @adapter && @adapter.respond_to?(:available?) && @adapter.available?
      end

      def persist_to_entity(entity, params)
        return unless @adapter.respond_to?(:set_attr)
        @adapter.set_attr(entity, 'params_json', JSON.generate(params))
        @adapter.set_attr(entity, 'revision', 1)
      rescue StandardError
        nil
      end
    end
  end
end
