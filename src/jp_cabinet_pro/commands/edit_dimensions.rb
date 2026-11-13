# frozen_string_literal: true

require_relative '../parametric/dimensions'
require_relative '../cabinet/construction'
require_relative '../bom/generator'
require_relative '../cutlist/generator'
require_relative '../drawing/technical_view'
require_relative '../materials/engine'
require_relative '../edge_banding/engine'
require_relative '../nesting/optimizer'
require_relative '../persistence/snapshot'
require_relative '../diagnostics/revision_tracker'

module JPCabinetPro
  module Commands
    # Vertical slice: Select Cabinet -> Edit Dimensions -> Rebuild Geometry -> Update BOM -> Generate Technical View
    # Full SketchUp selection/mutation requires runtime; this class provides the orchestration pipeline.
    class EditDimensions
      Result = Struct.new(:ok, :errors, :preview, :applied, :bom, :cutlist, :view, :view_svg, :revision,
                          :invalidations, :snapshot, :materials, :edge_banding, :nesting, :revision_state, keyword_init: true)

      INVALIDATIONS = %w[geometry parts materials edge_banding hardware bom cutlist nesting drawings reports].freeze

      def initialize(adapter: nil, materials_engine: nil, edge_banding_engine: nil, nesting_optimizer: nil, revision_tracker: nil)
        @adapter = adapter
        @construction = JPCabinetPro::Cabinet::Construction.new(adapter: adapter)
        @bom = JPCabinetPro::Bom::Generator.new
        @cutlist = JPCabinetPro::Cutlist::Generator.new
        @drawing = JPCabinetPro::Drawing::TechnicalView.new
        @materials = materials_engine || JPCabinetPro::Materials::Engine.new
        @edge_banding = edge_banding_engine || JPCabinetPro::EdgeBanding::Engine.new
        @nesting = nesting_optimizer || JPCabinetPro::Nesting::Optimizer.new
        @revision_tracker = revision_tracker
      end

      def preview(input)
        validated = JPCabinetPro::Parametric::Dimensions.validate(input)
        return Result.new(ok: false, errors: validated.errors, applied: false) unless validated.ok
        parts = @construction.build_parts(validated.values)
        rebuild_meta = @construction.rebuild(params: validated.values)
        Result.new(
          ok: true,
          errors: [],
          preview: {
            params: validated.values,
            parts: parts,
            construction: rebuild_meta[:construction]
          },
          applied: false
        )
      end

      def apply(input, assembly_id: 'asm_default', project_id: nil, revision: 1, existing: nil,
                waste_factor: 0.0, nesting_sheets: nil, nesting_strategy: 'maxrects')
        p = preview(input)
        return p unless p.ok

        tracker = @revision_tracker
        tracker&.touch!(assembly_id, revision)

        rebuild = if @adapter && @adapter.respond_to?(:transaction)
                    @adapter.transaction('JP Cabinet PRO: Edit Dimensions') { @construction.rebuild(params: p.preview[:params], existing: existing) }
                  else
                    @construction.rebuild(params: p.preview[:params], existing: existing)
                  end
        return Result.new(ok: false, errors: [rebuild[:error] || 'rebuild_failed']) unless rebuild && rebuild[:ok]

        bom = @bom.generate(parts: rebuild[:parts], assembly_id: assembly_id)
        cut = @cutlist.generate(bom)
        view = @drawing.generate(parts: bom, cabinet_params: p.preview[:params], view_type: :front, revision: revision)
        view_svg = safe_svg(view)
        materials = @materials.quantities(bom, waste_factor: waste_factor)
        edge_banding = @edge_banding.total_length(bom)
        nesting = compute_nesting(cut, nesting_sheets, nesting_strategy)

        revision_state = update_revision_tracker(tracker, assembly_id, nesting)

        snapshot = JPCabinetPro::Persistence::Snapshot.build(
          revision: revision,
          project_id: project_id,
          assembly_id: assembly_id,
          params: p.preview[:params],
          bom: bom,
          cutlist: cut,
          view: view,
          materials: materials,
          edge_banding: edge_banding,
          nesting: nesting,
          view_svg: view_svg,
          metadata: { invalidations: INVALIDATIONS, revision_state: revision_state }
        )

        Result.new(
          ok: true, errors: [], preview: p.preview, applied: true,
          bom: bom, cutlist: cut, view: view, view_svg: view_svg, revision: revision,
          invalidations: INVALIDATIONS, snapshot: snapshot,
          materials: materials, edge_banding: edge_banding, nesting: nesting,
          revision_state: revision_state
        )
      rescue StandardError => e
        Result.new(ok: false, errors: [e.message])
      end

      private

      def update_revision_tracker(tracker, assembly_id, nesting)
        return nil unless tracker
        # outputs produced by this pipeline in prototype form
        produced = [:geometry, :parts, :materials, :edge_banding, :bom, :cutlist, :drawings]
        produced << :nesting if nesting && nesting[:ok]
        tracker.mark_valid!(assembly_id, *produced)
        # hardware/reports not produced by this command
        tracker.snapshot(assembly_id)
      end

      def safe_svg(view_model)
        @drawing.to_svg(view_model)
      rescue StandardError
        nil
      end

      def compute_nesting(cutlist, sheets, strategy)
        return nil if sheets.nil? || (sheets.respond_to?(:empty?) && sheets.empty?)
        parts = Array(cutlist).map do |it|
          h = it.is_a?(Hash) ? it : it.to_h
          h = h.transform_keys(&:to_sym) if h.respond_to?(:transform_keys)
          {
            id: h[:part_id] || h[:part_name],
            w: h[:width],
            h: h[:length],
            qty: h[:quantity] || 1,
            material: h[:material],
            thickness: h[:thickness],
            grain: h[:grain_direction]
          }
        end
        @nesting.plan(parts, sheets, strategy: strategy)
      rescue StandardError => e
        { ok: false, error: e.message, placements: [], validated: false }
      end
    end
  end
end
