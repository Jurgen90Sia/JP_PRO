# frozen_string_literal: true

module JPCabinetPro
  module Bootstrap
    module Loader
      class << self
        def load!
          return if @loaded
          root = File.expand_path('..', __dir__)
          require File.join(root, 'diagnostics', 'logger.rb')
          require File.join(root, 'commands', 'registry.rb')
          require File.join(root, 'commands', 'factory.rb')
          require File.join(root, 'adapter', 'sketchup_adapter.rb')
          require File.join(root, 'persistence', 'store.rb')
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
          require File.join(root, 'commands', 'edit_dimensions.rb')
          require File.join(root, 'commands', 'plan_nesting.rb')
          require File.join(root, 'commands', 'generate_report.rb')
          require File.join(root, 'commands', 'export_cnc.rb')
          require File.join(root, 'commands', 'manage_library.rb')
          register_ui if sketchup_available?
          @loaded = true
          Diagnostics::Logger.info('JP Cabinet PRO loaded (dev scaffold)')
        rescue StandardError => e
          warn "[JP Cabinet PRO] Load failed: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
          raise
        end

        def sketchup_available?
          defined?(Sketchup) && Sketchup.respond_to?(:register_extension)
        end

        def register_ui
          Commands::Registry.register_defaults
          # Native toolbar/menu/context and HtmlDialog wiring to be added in Phase 9.
          # No decorative-only commands; handlers must be connected before exposing UI actions.
        end
      end
    end
  end
end

JPCabinetPro::Bootstrap::Loader.load!
