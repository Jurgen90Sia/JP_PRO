# frozen_string_literal: true

require_relative '../parametric/dimensions'
require_relative '../cabinet/construction'
require_relative '../bom/generator'
require_relative '../cutlist/generator'
require_relative '../drawing/technical_view'

module JPCabinetPro
  module Commands
    # Vertical slice: Select Cabinet -> Edit Dimensions -> Rebuild Geometry -> Update BOM -> Generate Technical View
    # Full SketchUp selection/mutation requires runtime; this class provides the orchestration pipeline.
    class EditDimensions
      Result = Struct.new(:ok, :errors, :preview, :applied, :bom, :cutlist, :view, :revision, keyword_init: true)

      def initialize(adapter: nil)
        @adapter = adapter
        @construction = JPCabinetPro::Cabinet::Construction.new(adapter: adapter)
        @bom = JPCabinetPro::Bom::Generator.new
        @cutlist = JPCabinetPro::Cutlist::Generator.new
        @drawing = JPCabinetPro::Drawing::TechnicalView.new
      end

      def preview(input)
        validated = JPCabinetPro::Parametric::Dimensions.validate(input)
        return Result.new(ok: false, errors: validated.errors) unless validated.ok
        parts = @construction.build_parts(validated.values)
        Result.new(ok: true, errors: [], preview: { params: validated.values, parts: parts }, applied: false)
      end

      def apply(input, assembly_id: 'asm_default', revision: 1)
        p = preview(input)
        return p unless p.ok

        # In SketchUp runtime: wrap geometry mutation in adapter.transaction with rollback on failure.
        rebuild = @construction.rebuild(params: p.preview[:params])
        return Result.new(ok: false, errors: ['rebuild_failed']) unless rebuild[:ok]

        bom = @bom.generate(parts: rebuild[:parts], assembly_id: assembly_id)
        cut = @cutlist.generate(bom)
        view = @drawing.generate(parts: bom, cabinet_params: p.preview[:params], view_type: :front, revision: revision)

        Result.new(
          ok: true, errors: [], preview: p.preview, applied: true,
          bom: bom, cutlist: cut, view: view, revision: revision
        )
      rescue StandardError => e
        Result.new(ok: false, errors: [e.message])
      end
    end
  end
end
