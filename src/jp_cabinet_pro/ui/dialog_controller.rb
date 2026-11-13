# frozen_string_literal: true

require 'json'

module JPCabinetPro
  module UI
    # HtmlDialog controller scaffold. Wires UI actions to registered commands via callbacks.
    # Native execution requires SketchUp HtmlDialog runtime; not verifiable in this environment.
    class DialogController
      def initialize(dialog:, command:)
        @dialog = dialog
        @command = command
      end

      def register_callbacks
        return unless @dialog.respond_to?(:add_action_callback)

        @dialog.add_action_callback('dimensions_preview') do |_ctx, payload_json|
          payload = parse(payload_json)
          result = @command.preview(payload)
          dispatch('dimensions_preview_result', serialize_result(result))
        end

        @dialog.add_action_callback('dimensions_apply') do |_ctx, payload_json|
          payload = parse(payload_json)
          result = @command.apply(payload)
          dispatch('dimensions_apply_result', serialize_result(result))
        end

        @dialog.add_action_callback('dimensions_cancel') do |_ctx, _payload_json|
          dispatch('dimensions_cancelled', { ok: true })
          @dialog.close if @dialog.respond_to?(:close)
        end
      end

      private

      def parse(payload_json)
        return {} if payload_json.nil? || payload_json == ''
        JSON.parse(payload_json, symbolize_names: true)
      rescue JSON::ParserError
        {}
      end

      def serialize_result(result)
        nesting = result.respond_to?(:nesting) ? result.nesting : nil
        {
          ok: result.ok,
          errors: result.errors,
          applied: result.applied,
          preview: result.preview,
          revision: result.revision,
          bom_count: result.bom ? result.bom.length : 0,
          cutlist_count: result.cutlist ? result.cutlist.length : 0,
          view: result.view,
          view_svg: (result.respond_to?(:view_svg) ? result.view_svg : nil),
          materials: result.respond_to?(:materials) ? result.materials : nil,
          edge_banding_count: (result.respond_to?(:edge_banding) && result.edge_banding) ? result.edge_banding.length : 0,
          fronts_count: (result.respond_to?(:fronts) && result.fronts) ? result.fronts.length : 0,
          drawers_count: (result.respond_to?(:drawers) && result.drawers) ? result.drawers.length : 0,
          hardware_count: (result.respond_to?(:hardware) && result.hardware) ? result.hardware.length : 0,
          nesting: nesting_summary(nesting),
          invalidations: result.invalidations,
          revision_state: result.respond_to?(:revision_state) ? result.revision_state : nil
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
    end
  end
end
