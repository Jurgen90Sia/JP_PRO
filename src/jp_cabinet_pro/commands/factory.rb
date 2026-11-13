# frozen_string_literal: true

require_relative 'edit_dimensions'
require_relative 'plan_nesting'
require_relative 'generate_report'
require_relative 'export_cnc'
require_relative 'manage_library'

module JPCabinetPro
  module Commands
    # Resolves command handlers for UI/registry integration (scaffold).
    module Factory
      module_function

      def build(id, adapter: nil, **opts)
        case id.to_s
        when 'cabinet.edit_dimensions'
          EditDimensions.new(adapter: adapter)
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
