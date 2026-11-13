# frozen_string_literal: true

require_relative '../ui/dialog'

module JPCabinetPro
  module Commands
    # Shows the main HtmlDialog UI (SketchUp runtime). Non-runtime returns status.
    class ShowDialog
      Result = Struct.new(:ok, :errors, :shown, keyword_init: true)

      def initialize(adapter: nil, command: nil)
        @adapter = adapter
        @command = command
      end

      def execute(page: 'app')
        unless defined?(::UI) && defined?(::UI::HtmlDialog)
          return Result.new(ok: false, errors: ['sketchup_runtime_required'], shown: false)
        end
        dlg = JPCabinetPro::UI::Dialog.app_dialog(command: @command, adapter: @adapter, page: page)
        if dlg.respond_to?(:show)
          dlg.show
          Result.new(ok: true, errors: [], shown: true)
        elsif dlg.is_a?(Hash) && dlg[:ok] == false
          Result.new(ok: false, errors: [dlg[:error] || 'dialog_failed'], shown: false)
        else
          Result.new(ok: true, errors: [], shown: true)
        end
      rescue StandardError => e
        Result.new(ok: false, errors: [e.message], shown: false)
      end
    end
  end
end
