# frozen_string_literal: true

module JPCabinetPro
  module Bootstrap
    module Loader
      class << self
        def load!
          return if @loaded
          root = File.expand_path('..', __dir__)
          require File.join(root, 'diagnostics', 'logger.rb')
          require File.join(root, 'diagnostics', 'revision_tracker.rb')
          require File.join(root, 'commands', 'registry.rb')
          require File.join(root, 'commands', 'factory.rb')
          require File.join(root, 'adapter', 'sketchup_adapter.rb')
          require File.join(root, 'selection', 'extractor.rb')
          require File.join(root, 'observers', 'app_observer.rb')
          require File.join(root, 'cabinet', 'builder.rb')
          require File.join(root, 'persistence', 'store.rb')
          require File.join(root, 'persistence', 'snapshot.rb')
          require File.join(root, 'parametric', 'dimensions.rb')
          require File.join(root, 'cabinet', 'construction.rb')
          require File.join(root, 'bom', 'generator.rb')
          require File.join(root, 'cutlist', 'generator.rb')
          require File.join(root, 'drawing', 'technical_view.rb')
          require File.join(root, 'materials', 'engine.rb')
          require File.join(root, 'edge_banding', 'engine.rb')
          require File.join(root, 'nesting', 'optimizer.rb')
          require File.join(root, 'report', 'generator.rb')
          require File.join(root, 'cnc', 'exporter.rb')
          require File.join(root, 'library', 'manager.rb')
          require File.join(root, 'doors', 'front_engine.rb')
          require File.join(root, 'drawers', 'engine.rb')
          require File.join(root, 'hardware', 'engine.rb')
          require File.join(root, 'commands', 'edit_dimensions.rb')
          require File.join(root, 'commands', 'create_cabinet.rb')
          require File.join(root, 'commands', 'apply_to_selection.rb')
          require File.join(root, 'commands', 'plan_nesting.rb')
          require File.join(root, 'commands', 'generate_report.rb')
          require File.join(root, 'commands', 'export_cnc.rb')
          require File.join(root, 'commands', 'manage_library.rb')
          require File.join(root, 'commands', 'show_dialog.rb')
          require File.join(root, 'ui', 'dialog_controller.rb')
          require File.join(root, 'ui', 'dialog.rb')
          register_ui if sketchup_available?
          @loaded = true
          Diagnostics::Logger.info('JP Cabinet PRO loaded')
        rescue StandardError => e
          warn "[JP Cabinet PRO] Load failed: #{e.message}\n#{e.backtrace&.first(8)&.join("\n")}"
          raise
        end

        def sketchup_available?
          defined?(::Sketchup) && defined?(::UI)
        end

        def register_ui
          Commands::Registry.register_defaults
          build_ui_elements
          Observers::Manager.attach(::Sketchup.active_model)
        rescue StandardError => e
          Diagnostics::Logger.error("UI registration failed: #{e.message}")
        end

        def build_ui_elements
          return unless defined?(::UI)
          @ui_built ||= false
          return if @ui_built

          adapter = Adapter::SketchupAdapter.new
          cmd_show = ::UI::Command.new('JP Cabinet PRO') { Commands::Factory.build('app.show', adapter: adapter)&.execute(page: 'app') }
          set_command_meta(cmd_show, 'JP Cabinet PRO', 'Open JP Cabinet PRO panel', 'icons/svg/cabinet.svg')

          cmd_edit = ::UI::Command.new('Edit Dimensions') { Commands::Factory.build('app.show', adapter: adapter)&.execute(page: 'dimensions') }
          set_command_meta(cmd_edit, 'Edit Dimensions', 'Edit selected cabinet dimensions', 'icons/svg/dimensions.svg')

          cmd_create = ::UI::Command.new('Create Cabinet') { Commands::Factory.build('cabinet.create', adapter: adapter)&.execute({}) }
          set_command_meta(cmd_create, 'Create Cabinet', 'Create a parametric cabinet', 'icons/svg/cabinet.svg')

          toolbar = ::UI::Toolbar.new('JP Cabinet PRO')
          toolbar.add_item(cmd_show)
          toolbar.add_item(cmd_create)
          toolbar.add_item(cmd_edit)
          toolbar.restore if toolbar.respond_to?(:restore)

          menu = ::UI.menu('Extensions') rescue (::UI.menu('Plugins') rescue nil)
          if menu
            sub = menu.add_submenu('JP Cabinet PRO')
            sub.add_item(cmd_show)
            sub.add_item(cmd_create)
            sub.add_item(cmd_edit)
          end

          if ::UI.respond_to?(:add_context_menu_handler)
            ::UI.add_context_menu_handler do |ctx|
              begin
                sel = ::Sketchup.active_model.selection rescue nil
                if sel && !sel.empty?
                  ctx.add_item('JP Cabinet PRO: Edit Dimensions') { Commands::Factory.build('app.show', adapter: adapter)&.execute(page: 'dimensions') }
                end
              rescue StandardError
                # ignore
              end
            end
          end

          @ui_built = true
        end

        def set_command_meta(cmd, name, tooltip, icon_rel)
          cmd.tooltip = tooltip
          cmd.status_bar_text = tooltip
          cmd.menu_text = name
          if cmd.respond_to?(:small_icon=)
            icon = icon_path(icon_rel)
            if icon && File.exist?(icon)
              cmd.small_icon = icon
              cmd.large_icon = icon
            end
          end
        rescue StandardError
          nil
        end

        def icon_path(rel)
          File.expand_path(File.join('..', '..', '..', rel), __dir__)
        end
      end
    end
  end
end

JPCabinetPro::Bootstrap::Loader.load!
