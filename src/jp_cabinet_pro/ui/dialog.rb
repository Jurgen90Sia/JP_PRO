# frozen_string_literal: true

require 'json'

module JPCabinetPro
  module UI
    # Factory for HtmlDialog instances (SketchUp runtime). Not verifiable in this environment.
    module Dialog
      module_function

      def dimensions_dialog(command:, title: 'JP Cabinet PRO - Edit Dimensions')
        return { ok: false, error: 'sketchup_runtime_required' } unless defined?(UI::HtmlDialog)

        html = File.join(root_path, 'ui', 'dialogs', 'dimensions.html')
        dlg = UI::HtmlDialog.new(
          dialog_title: title,
          preferences_key: 'jp_cabinet_pro.dimensions',
          scrollable: true,
          resizable: true,
          width: 520,
          height: 720,
          style: UI::HtmlDialog::STYLE_DIALOG
        )
        dlg.set_file(html)

        controller = DialogController.new(dialog: dlg, command: command)
        controller.register_callbacks
        dlg
      end

      def root_path
        File.expand_path('../../../..', __dir__)
      end
    end
  end
end
