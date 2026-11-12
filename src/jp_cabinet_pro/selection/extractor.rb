# frozen_string_literal: true

module JPCabinetPro
  module Selection
    # Selection and geometry extraction (scaffold).
    # Must handle nested groups, component instances, mirrored/rotated transforms without double counting.
    class Extractor
      def initialize(adapter:)
        @adapter = adapter
      end

      def selected_cabinet(_selection = nil)
        # Requires SketchUp selection; returns canonical cabinet reference or nil.
        { ok: false, error: 'sketchup_runtime_required' }
      end

      def extract_parts(_entity)
        { ok: false, error: 'sketchup_runtime_required', parts: [] }
      end
    end
  end
end
