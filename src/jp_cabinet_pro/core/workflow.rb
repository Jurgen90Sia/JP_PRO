# frozen_string_literal: true

require 'json'
require_relative '../parametric/dimensions'
require_relative '../cabinet/construction'
require_relative '../cabinet/builder'
require_relative '../bom/generator'
require_relative '../cutlist/generator'
require_relative '../drawing/technical_view'
require_relative '../materials/engine'
require_relative '../edge_banding/engine'
require_relative '../nesting/optimizer'
require_relative '../report/generator'
require_relative '../persistence/snapshot'
require_relative '../diagnostics/revision_tracker'

module JPCabinetPro
  module Core
    # Orchestrates canonical workflow:
    # SketchUp cabinet (runtime) -> Parameters -> Geometry/Parts -> BOM -> CutList ->
    # Materials -> EdgeBanding -> Nesting -> Reports/Drawings -> Export
    # Tracks dependencies/invalidation so downstream outputs refresh from same snapshot inputs.
    class Workflow
      Result = Struct.new(:ok, :errors, :warnings, :params, :parts, :fronts, :drawers, :hardware,
                          :bom, :cutlist, :materials, :edge_banding, :nesting, :view, :view_svg,
                          :report, :report_html, :snapshot, :revision, :revision_state,
                          :invalidations, :stale, :entity_status, keyword_init: true)

      INVALIDATIONS = %w[geometry parts materials edge_banding hardware bom cutlist nesting drawings reports].freeze
      DEP_GRAPH = {
        'params' => %w[geometry parts],
        'geometry' => %w[parts materials edge_banding hardware bom cutlist nesting drawings reports],
        'parts' => %w[materials edge_banding hardware bom cutlist nesting drawings reports],
        'materials' => %w[reports],
        'edge_banding' => %w[reports],
        'hardware' => %w[bom reports],
        'bom' => %w[cutlist nesting drawings reports],
        'cutlist' => %w[nesting reports],
        'nesting' => %w[reports],
        'drawings' => %w[reports]
      }.freeze

      def initialize(adapter: nil, revision_tracker: nil)
        @adapter = adapter
        @revision_tracker = revision_tracker || JPCabinetPro::Diagnostics::RevisionTracker.new
        @construction = JPCabinetPro::Cabinet::Construction.new(adapter: adapter)
        @builder = defined?(JPCabinetPro::Cabinet::Builder) ? JPCabinetPro::Cabinet::Builder.new(adapter: adapter) : nil
        @bom_gen = JPCabinetPro::Bom::Generator.new
        @cut_gen = JPCabinetPro::Cutlist::Generator.new
        @drawing = JPCabinetPro::Drawing::TechnicalView.new
        @materials = JPCabinetPro::Materials::Engine.new
        @edge_banding = JPCabinetPro::EdgeBanding::Engine.new
        @nesting = JPCabinetPro::Nesting::Optimizer.new
        @report = JPCabinetPro::Report::Generator.new
      end

      attr_reader :revision_tracker

      def affected(change)
        out = []
        q = Array(change).map(&:to_s)
        seen = {}
        until q.empty?
          c = q.shift
          next if seen[c]
          seen[c] = true
          deps = DEP_GRAPH[c] || []
          deps.each { |d| out << d unless out.include?(d); q << d }
        end
        out
      end

      def run(input, assembly_id: 'asm_default', project_id: nil, revision: 1, existing: nil,
              waste_factor: 0.0, nesting_sheets: nil, nesting_strategy: 'maxrects',
              generate_report: false, report_options: {})
        validated = JPCabinetPro::Parametric::Dimensions.validate(input || {})
        return Result.new(ok: false, errors: validated.errors, warnings: validated.warnings, params: validated.values) unless validated.ok

        params = validated.values
        @revision_tracker.touch!(assembly_id, revision)
        entity_status = { runtime: runtime?, rebuilt: false, created: false }

        rebuild = @construction.rebuild(params: params, existing: existing)
        return Result.new(ok: false, errors: [rebuild[:error] || 'rebuild_failed'], params: params, entity_status: entity_status) unless rebuild && rebuild[:ok]

        apply_runtime_geometry(params, rebuild[:parts] || [], existing, entity_status)

        parts = Array(rebuild[:parts])
        fronts = Array(rebuild[:fronts])
        drawers = Array(rebuild[:drawers])
        hardware = Array(rebuild[:hardware])
        all_parts = collect_all_parts(rebuild)

        bom = @bom_gen.generate(parts: all_parts, assembly_id: assembly_id)
        cutlist = @cut_gen.generate(bom)
        materials = @materials.quantities(bom, waste_factor: waste_factor)
        edge_banding = @edge_banding.total_length(bom)
        view = @drawing.generate(parts: bom, cabinet_params: params, view_type: :front, revision: revision)
        view_svg = safe_svg(view)
        nesting = compute_nesting(cutlist, nesting_sheets, nesting_strategy)

        valid_outputs = [:geometry, :parts, :materials, :edge_banding, :hardware, :bom, :cutlist, :drawings]
        valid_outputs << :nesting if nesting && nesting[:ok]
        @revision_tracker.mark_valid!(assembly_id, *valid_outputs)
        revision_state = @revision_tracker.snapshot(assembly_id)

        snapshot = JPCabinetPro::Persistence::Snapshot.build(
          revision: revision, project_id: project_id, assembly_id: assembly_id, params: params,
          bom: bom, cutlist: cutlist, view: view, materials: materials, edge_banding: edge_banding,
          nesting: nesting, view_svg: view_svg,
          metadata: {
            invalidations: INVALIDATIONS, revision_state: revision_state,
            fronts: fronts, drawers: drawers, hardware: hardware, entity_status: entity_status,
            warnings: validated.warnings
          }
        )

        report = nil
        report_html = nil
        if generate_report
          rr = @report.generate(snapshot, report_options || {})
          if rr.ok
            report = rr.report
            report_html = rr.html
            @revision_tracker.mark_valid!(assembly_id, :reports)
            revision_state = @revision_tracker.snapshot(assembly_id)
          end
        end

        Result.new(
          ok: true, errors: [], warnings: validated.warnings, params: params,
          parts: parts, fronts: fronts, drawers: drawers, hardware: hardware,
          bom: bom, cutlist: cutlist, materials: materials, edge_banding: edge_banding,
          nesting: nesting, view: view, view_svg: view_svg,
          report: report, report_html: report_html,
          snapshot: snapshot, revision: revision, revision_state: revision_state,
          invalidations: INVALIDATIONS, stale: revision_state ? revision_state[:stale] : [],
          entity_status: entity_status
        )
      rescue StandardError => e
        Result.new(ok: false, errors: [e.message])
      end

      private

      def runtime?
        @adapter && @adapter.respond_to?(:available?) && @adapter.available?
      end

      def apply_runtime_geometry(params, parts, existing, entity_status)
        return unless runtime? && @builder
        if existing
          br = @builder.rebuild(entity: existing, params: params, parts: parts)
          entity_status[:rebuilt] = br.ok
          entity_status[:entity_errors] = br.errors unless br.ok
        else
          br = @builder.create(params: params, parts: parts)
          entity_status[:created] = br.ok
          entity_status[:entity] = br.entity if br.ok
          entity_status[:entity_errors] = br.errors unless br.ok
        end
      rescue StandardError => e
        entity_status[:entity_errors] = [e.message]
      end

      def collect_all_parts(rebuild)
        parts = Array(rebuild[:parts]).dup
        Array(rebuild[:fronts]).each { |f| parts << f }
        Array(rebuild[:drawers]).each do |d|
          Array(d[:parts]).each { |p| parts << p }
        end
        parts
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
        @nesting.plan(parts, sheets, strategy: strategy || 'maxrects')
      rescue StandardError => e
        { ok: false, error: e.message, placements: [], validated: false }
      end
    end
  end
end
