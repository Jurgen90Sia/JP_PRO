# frozen_string_literal: true

require 'json'

module JPCabinetPro
  module UI
    # HtmlDialog controller. Wires UI actions to real engines/commands via callbacks.
    # All execution paths are guarded; SketchUp-specific side effects require runtime.
    class DialogController
      def initialize(dialog:, command: nil, adapter: nil)
        @dialog = dialog
        @command = command
        @adapter = adapter
      end

      def register_callbacks
        return unless @dialog.respond_to?(:add_action_callback)

        on('dimensions_preview') { |p| handle_dimensions_preview(p) }
        on('dimensions_apply') { |p| handle_dimensions_apply(p) }
        on('dimensions_cancel') { |_p| dispatch('dimensions_cancelled', { ok: true }); close if @dialog.respond_to?(:close) }

        on('cabinet_create') { |p| handle_cabinet_create(p) }
        on('selection_apply') { |p| handle_selection_apply(p) }
        on('selection_read') { |_p| handle_selection_read }

        on('nesting_plan') { |p| handle_nesting(p) }
        on('report_generate') { |p| handle_report(p) }
        on('export_csv') { |p| handle_export_csv(p) }
        on('export_nesting_dxf') { |p| handle_export_nesting_dxf(p) }

        on('library_action') { |p| handle_library(p) }
        on('diagnostics_info') { |_p| handle_diagnostics }
      end

      private

      def on(name, &block)
        @dialog.add_action_callback(name) do |_ctx, payload_json|
          payload = parse(payload_json)
          block.call(payload)
        rescue StandardError => e
          dispatch("#{name}_result", { ok: false, errors: [e.message] })
        end
      end

      def parse(payload_json)
        return {} if payload_json.nil? || payload_json == ''
        parsed = JSON.parse(payload_json, symbolize_names: true)
        parsed.is_a?(Hash) ? parsed : { value: parsed }
      rescue JSON::ParserError
        {}
      end

      def handle_dimensions_preview(payload)
        cmd = ensure_edit_command
        result = cmd.preview(payload)
        dispatch('dimensions_preview_result', serialize_edit_result(result))
      end

      def handle_dimensions_apply(payload)
        cmd = ensure_edit_command
        opts = extract_opts(payload)
        result = cmd.apply(payload, **opts)
        dispatch('dimensions_apply_result', serialize_edit_result(result))
      end

      def handle_cabinet_create(payload)
        require_relative '../commands/create_cabinet'
        cmd = JPCabinetPro::Commands::CreateCabinet.new(adapter: @adapter)
        res = cmd.execute(payload)
        dispatch('cabinet_create_result', { ok: res.ok, errors: res.errors || [], params: res.params, parts_count: (res.parts || []).length, entity_status: res.entity_status })
      end

      def handle_selection_apply(payload)
        require_relative '../commands/apply_to_selection'
        cmd = JPCabinetPro::Commands::ApplyToSelection.new(adapter: @adapter)
        res = cmd.execute(payload, revision: (payload[:revision] || 1).to_i)
        detail = { ok: res.ok, errors: res.errors || [], applied: res.applied }
        detail[:result] = serialize_edit_result(res.result) if res.result
        dispatch('selection_apply_result', detail)
      end

      def handle_selection_read
        info = { ok: true, runtime: runtime?, selected: false, params: nil }
        if runtime?
          require_relative '../selection/extractor'
          ex = JPCabinetPro::Selection::Extractor.new(adapter: @adapter)
          sel = ex.selected_cabinet
          if sel && sel.ok
            info[:selected] = true
            info[:params] = @adapter.read_params(sel.entity) if @adapter.respond_to?(:read_params)
            info[:entity_name] = (sel.entity.respond_to?(:name) ? sel.entity.name : nil)
          else
            info[:error] = sel ? sel.error : 'no_selection'
          end
        else
          info[:error] = 'sketchup_runtime_required'
        end
        dispatch('selection_read_result', info)
      end

      def handle_nesting(payload)
        require_relative '../commands/plan_nesting'
        parts = payload[:parts] || []
        sheets = payload[:sheets] || []
        strategy = payload[:strategy] || 'maxrects'
        res = JPCabinetPro::Commands::PlanNesting.new.execute(parts: parts, sheets: sheets, strategy: strategy)
        dispatch('nesting_plan_result', { ok: res.ok, errors: res.errors || [], nesting: res.nesting })
      end

      def handle_report(payload)
        require_relative '../commands/generate_report'
        snap = payload[:snapshot] || payload
        res = JPCabinetPro::Commands::GenerateReport.new.execute(snapshot: snap, options: payload[:options] || {})
        dispatch('report_generate_result', { ok: res.ok, errors: res.errors || [], html: res.html, report: res.report })
      end

      def handle_export_csv(payload)
        require_relative '../commands/export_cnc'
        res = JPCabinetPro::Commands::ExportCnc.new.export_csv(payload[:cutlist] || [], columns: payload[:columns])
        dispatch('export_csv_result', { ok: res.ok, errors: res.errors || [], content: res.export&.content, format: res.export&.format, note: res.export&.note })
      end

      def handle_export_nesting_dxf(payload)
        require_relative '../commands/export_cnc'
        res = JPCabinetPro::Commands::ExportCnc.new.export_nesting_dxf(payload[:nesting] || {}, sheets: payload[:sheets] || [])
        dispatch('export_nesting_dxf_result', { ok: res.ok, errors: res.errors || [], content: res.export&.content, format: res.export&.format, note: res.export&.note })
      end

      def handle_library(payload)
        require_relative '../commands/manage_library'
        action = (payload[:action] || 'search').to_s
        cmd = JPCabinetPro::Commands::ManageLibrary.new(index_path: payload[:index_path])
        r = case action
            when 'search' then cmd.search(payload[:query], category: payload[:category], favorites_only: !!payload[:favorites_only], recent_only: !!payload[:recent_only], limit: payload[:limit])
            when 'upsert' then cmd.upsert(payload[:component] || {})
            when 'import' then cmd.import(payload[:path])
            when 'export' then cmd.export(payload[:id], payload[:path])
            else cmd.search(payload[:query])
            end
        items = r.result.respond_to?(:items) ? r.result.items : nil
        item = r.result.respond_to?(:item) ? r.result.item : nil
        status = r.result.respond_to?(:status) ? r.result.status : nil
        dispatch('library_action_result', { ok: r.ok, errors: r.errors || [], action: action, items: items, item: item, status: status })
      end

      def handle_diagnostics
        info = {
          ok: true,
          extension: defined?(JPCabinetPro::EXTENSION_VERSION) ? JPCabinetPro::EXTENSION_VERSION : 'dev',
          runtime: runtime?,
          ruby: RUBY_VERSION,
          platform: RUBY_PLATFORM,
          registered_commands: (defined?(JPCabinetPro::Commands::Registry) ? JPCabinetPro::Commands::Registry.commands.keys : [])
        }
        dispatch('diagnostics_info_result', info)
      end

      def ensure_edit_command
        @command ||= JPCabinetPro::Commands::EditDimensions.new(adapter: @adapter)
      end

      def runtime?
        @adapter && @adapter.respond_to?(:available?) && @adapter.available?
      end

      def extract_opts(payload)
        opts = {}
        opts[:assembly_id] = payload[:assembly_id] if payload[:assembly_id]
        opts[:project_id] = payload[:project_id] if payload[:project_id]
        opts[:revision] = payload[:revision].to_i if payload[:revision]
        opts[:waste_factor] = payload[:waste_factor].to_f if payload.key?(:waste_factor)
        opts[:nesting_sheets] = payload[:nesting_sheets] if payload[:nesting_sheets]
        opts[:nesting_strategy] = payload[:nesting_strategy] if payload[:nesting_strategy]
        opts
      end

      def serialize_edit_result(result)
        nesting = result.respond_to?(:nesting) ? result.nesting : nil
        {
          ok: result.ok,
          errors: result.errors,
          applied: result.applied,
          preview: result.preview,
          revision: result.revision,
          bom_count: result.bom ? result.bom.length : 0,
          cutlist_count: result.cutlist ? result.cutlist.length : 0,
          bom: result.bom,
          cutlist: result.cutlist,
          view: result.view,
          view_svg: (result.respond_to?(:view_svg) ? result.view_svg : nil),
          materials: result.respond_to?(:materials) ? result.materials : nil,
          edge_banding: result.respond_to?(:edge_banding) ? result.edge_banding : nil,
          edge_banding_count: (result.respond_to?(:edge_banding) && result.edge_banding) ? result.edge_banding.length : 0,
          fronts_count: (result.respond_to?(:fronts) && result.fronts) ? result.fronts.length : 0,
          drawers_count: (result.respond_to?(:drawers) && result.drawers) ? result.drawers.length : 0,
          hardware_count: (result.respond_to?(:hardware) && result.hardware) ? result.hardware.length : 0,
          nesting: nesting_summary(nesting),
          nesting_full: nesting,
          invalidations: result.invalidations,
          revision_state: result.respond_to?(:revision_state) ? result.revision_state : nil,
          snapshot: result.respond_to?(:snapshot) ? result.snapshot : nil,
          entity_status: result.respond_to?(:entity_status) ? result.entity_status : nil
        }
      end

      def nesting_summary(nesting)
        return nil unless nesting.is_a?(Hash)
        {
          ok: nesting[:ok],
          strategy: nesting[:strategy],
          validated: nesting[:validated],
          utilization: nesting[:utilization],
          placements_count: (nesting[:placements] || []).length,
          unplaced_count: (nesting[:unplaced] || []).length,
          sheets_used: nesting[:sheets_used] || []
        }
      end

      def dispatch(event, detail)
        json = JSON.generate(detail)
        if @dialog.respond_to?(:execute_script)
          @dialog.execute_script("window.dispatchEvent(new CustomEvent('#{event}', {detail: #{json}}));")
        end
      end

      def close
        @dialog.close if @dialog.respond_to?(:close)
      rescue StandardError
        nil
      end
    end
  end
end
