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

        def register_defaults
          # Phase 1 scaffold: vertical slice command placeholder (not fully implemented).
          register(
            id: 'cabinet.edit_dimensions',
            icon: nil,
            label_sq: 'Ndrysho dimensionet',
            label_en: 'Edit Dimensions',
            input_schema: {
              width_mm: :float, height_mm: :float, depth_mm: :float,
              panel_thickness_mm: :float, shelf_count: :integer,
              back_mount_type: :string, groove_depth_mm: :float, rear_inset_mm: :float
            },
            validation: 'pending_implementation',
            handler: nil,
            required_selection: 'cabinet',
            undo_behavior: 'single_transaction',
            test_id: 'cmd.cabinet.edit_dimensions'
          )
        end
      end
    end
  end
end
