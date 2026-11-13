# frozen_string_literal: true

require_relative '../library/manager'

module JPCabinetPro
  module Commands
    # Prototype library command wrapper. SketchUp insert/replace require runtime.
    class ManageLibrary
      Result = Struct.new(:ok, :errors, :result, keyword_init: true)

      def initialize(manager: nil, index_path: nil)
        @manager = manager || JPCabinetPro::Library::Manager.new(index_path: index_path)
      end

      attr_reader :manager

      def search(query = nil, **filters)
        wrap(@manager.search(query, **filters))
      end

      def upsert(component)
        wrap(@manager.upsert(component))
      end

      def import(path)
        wrap(@manager.import(path))
      end

      def export(id, path)
        wrap(@manager.export(id, path))
      end

      private

      def wrap(r)
        errors = r.respond_to?(:errors) ? (r.errors || []) : []
        ok = r.respond_to?(:ok) ? r.ok : true
        Result.new(ok: ok, errors: errors, result: r)
      end
    end
  end
end
