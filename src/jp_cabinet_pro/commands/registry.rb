# frozen_string_literal: true

module JPCabinetPro
  module Commands
    # Central command registry. Every UI action must bind to a registered command.
    # Contract per command: id, icon, label_sq, label_en, input_schema, validation,
    # handler, required_selection, undo_behavior, test_id.
    module Registry
      class << self
        def commands
          @commands ||= {}
        end

        def register(cmd)
          raise ArgumentError, 'command id required' unless cmd && cmd[:id]
          commands[cmd[:id]] = cmd
          cmd
        end

        def fetch(id)
          commands[id]
        end

        def all
          commands.values
        end

        def register_defaults
          return if @defaults_registered
          register(
            id: 'cabinet.edit_dimensions',
            icon: 'icons/svg/dimensions.svg',
            label_sq: 'Ndrysho dimensionet',
            label_en: 'Edit Dimensions',
            input_schema: {
              width_mm: :float, height_mm: :float, depth_mm: :float,
              panel_thickness_mm: :float, shelf_count: :integer,
              top_construction: :string, bottom_construction: :string,
              back_mount_type: :string, groove_depth_mm: :float, rear_inset_mm: :float,
              nesting_sheets: :array_optional, nesting_strategy: :string_optional
            },
            validation: 'JPCabinetPro::Parametric::Dimensions.validate',
            handler: 'JPCabinetPro::Commands::EditDimensions',
            required_selection: 'cabinet',
            undo_behavior: 'single_transaction_apply',
            test_id: 'cmd.cabinet.edit_dimensions'
          )
          register(
            id: 'nesting.plan',
            icon: 'icons/svg/nesting.svg',
            label_sq: 'Optimizimi i fletëve',
            label_en: 'Plan Nesting',
            input_schema: { parts: :array, sheets: :array, strategy: :string },
            validation: 'prototype_basic_required',
            handler: 'JPCabinetPro::Commands::PlanNesting',
            required_selection: 'none',
            undo_behavior: 'none_calculation',
            test_id: 'cmd.nesting.plan'
          )
          register(
            id: 'report.generate',
            icon: 'icons/svg/drawing.svg',
            label_sq: 'Gjenero raport',
            label_en: 'Generate Report',
            input_schema: { snapshot: :object, options: :object_optional },
            validation: 'snapshot_required',
            handler: 'JPCabinetPro::Commands::GenerateReport',
            required_selection: 'none',
            undo_behavior: 'none',
            test_id: 'cmd.report.generate'
          )
          register(
            id: 'cnc.export_csv',
            icon: 'icons/svg/bom.svg',
            label_sq: 'Eksporto CSV',
            label_en: 'Export CSV',
            input_schema: { cutlist: :array, columns: :array_optional },
            validation: 'prototype',
            handler: 'JPCabinetPro::Commands::ExportCnc#export_csv',
            required_selection: 'none',
            undo_behavior: 'none',
            test_id: 'cmd.cnc.export_csv'
          )
          register(
            id: 'cnc.export_nesting_dxf',
            icon: 'icons/svg/nesting.svg',
            label_sq: 'Eksporto DXF nesting',
            label_en: 'Export Nesting DXF',
            input_schema: { nesting_result: :object, sheets: :array },
            validation: 'prototype',
            handler: 'JPCabinetPro::Commands::ExportCnc#export_nesting_dxf',
            required_selection: 'none',
            undo_behavior: 'none',
            test_id: 'cmd.cnc.export_nesting_dxf'
          )
          register(
            id: 'library.manage',
            icon: 'icons/svg/cabinet.svg',
            label_sq: 'Libraria e komponentëve',
            label_en: 'Component Library',
            input_schema: { action: :string, payload: :object_optional },
            validation: 'prototype',
            handler: 'JPCabinetPro::Commands::ManageLibrary',
            required_selection: 'none',
            undo_behavior: 'none_or_context',
            test_id: 'cmd.library.manage'
          )
          @defaults_registered = true
        end
      end
    end
  end
end
