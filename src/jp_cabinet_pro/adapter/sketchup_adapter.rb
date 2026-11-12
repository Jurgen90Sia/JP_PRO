# frozen_string_literal: true

module JPCabinetPro
  module Adapter
    # Isolates SketchUp API calls. All destructive operations must be transaction-safe.
    class SketchupAdapter
      def initialize(model: nil)
        @model = model || (defined?(Sketchup) ? Sketchup.active_model : nil)
      end

      attr_reader :model

      def transaction(name)
        raise 'No active SketchUp model' unless model
        model.start_operation(name, true)
        result = yield
        model.commit_operation
        result
      rescue StandardError => e
        model.abort_operation if model
        raise e
      end

      # Geometry extraction/mutation methods added per vertical slice; no unrelated model changes.
    end
  end
end
