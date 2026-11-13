# frozen_string_literal: true

require_relative 'edit_dimensions'
require_relative 'create_cabinet'
require_relative 'apply_to_selection'
require_relative 'plan_nesting'
require_relative 'generate_report'
require_relative 'export_cnc'
require_relative 'manage_library'
require_relative 'show_dialog'

module JPCabinetPro
  module Commands
    # Resolves command handlers for UI/registry integration.
    module Factory
      module_function

      def build(id, adapter: nil, **opts)
        case id.to_s
        when 'app.show'
          ShowDialog.new(adapter: adapter, command: opts[:command] || EditDimensions.new(adapter: adapter))
        when 'cabinet.create'
          CreateCabinet.new(adapter: adapter)
        when 'cabinet.edit_dimensions'
          EditDimensions.new(adapter: adapter)
        when 'cabinet.apply_selection'
          ApplyToSelection.new(adapter: adapter)
        when 'nesting.plan'
          PlanNesting.new
        when 'report.generate'
          GenerateReport.new
        when 'cnc.export_csv', 'cnc.export_nesting_dxf'
          ExportCnc.new
        when 'library.manage'
          ManageLibrary.new(index_path: opts[:index_path])
        else
          nil
        end
      end
    end
  end
end
