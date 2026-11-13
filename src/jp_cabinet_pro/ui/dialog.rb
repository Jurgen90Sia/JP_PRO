# frozen_string_literal: true

require 'json'

module JPCabinetPro
  module UI
    # Factory for HtmlDialog instances (SketchUp runtime). Not verifiable in this environment.
    module Dialog
      module_function

      def app_dialog(command: nil, adapter: nil, page: 'app', title: 'JP Cabinet PRO')
        return { ok: false, error: 'sketchup_runtime_required' } unless defined?(::UI::HtmlDialog)

        html = File.join(root_path, 'ui', 'index.html')
        dlg = ::UI::HtmlDialog.new(
          dialog_title: title,
          preferences_key: 'jp_cabinet_pro.app',
          scrollable: true,
          resizable: true,
          width: 980,
          height: 760,
          style: ::UI::HtmlDialog::STYLE_DIALOG
        )
        dlg.set_file(html)

        edit_cmd = command || (defined?(JPCabinetPro::Commands::EditDimensions) ? JPCabinetPro::Commands::EditDimensions.new(adapter: adapter) : nil)
        controller = DialogController.new(dialog: dlg, command: edit_cmd, adapter: adapter)
        controller.register_callbacks

        if dlg.respond_to?(:set_on_completed)
          dlg.set_on_completed { dlg.execute_script("window.JPApp && window.JPApp.navigate && window.JPApp.navigate('#{page}')") rescue nil }
        end
        dlg
      end

      def dimensions_dialog(command:, title: 'JP Cabinet PRO - Edit Dimensions')
        # Backward-compatible helper
        app_dialog(command: command, page: 'dimensions', title: title)
      end

      def root_path
        File.expand_path('../../../..', __dir__)
      end
    end
  end
end
