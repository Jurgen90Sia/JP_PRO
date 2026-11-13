# frozen_string_literal: true

require_relative 'edit_dimensions'
require_relative '../selection/extractor'

module JPCabinetPro
  module Commands
    # Applies dimension/config updates to the selected JP cabinet in SketchUp runtime.
    # Falls back to pure pipeline result if no runtime/entity.
    class ApplyToSelection
      Result = Struct.new(:ok, :errors, :applied, :selection, :result, keyword_init: true)

      def initialize(adapter: nil)
        @adapter = adapter
        @edit = EditDimensions.new(adapter: adapter)
        @extractor = JPCabinetPro::Selection::Extractor.new(adapter: adapter)
      end

      def execute(input, revision: 1)
        sel = @extractor.selected_cabinet
        existing = (sel && sel.ok) ? sel.entity : nil
        res = @edit.apply(input, existing: existing, revision: revision)
        # persist params to entity on success
        if res.ok && existing && @adapter.respond_to?(:mark_cabinet!)
          @adapter.mark_cabinet!(existing, res.preview ? res.preview[:params] : {}, { 'revision' => revision })
        end
        Result.new(ok: res.ok, errors: res.errors, applied: res.applied, selection: sel, result: res)
      rescue StandardError => e
        Result.new(ok: false, errors: [e.message], applied: false)
      end
    end
  end
end
