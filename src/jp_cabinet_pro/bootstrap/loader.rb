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
          require File.join(root, 'adapter', 'sketchup_adapter.rb')
          require File.join(root, 'persistence', 'store.rb')
          register_ui if defined?(Sketchup) && Sketchup.respond_to?(:register_extension)
          @loaded = true
          Diagnostics::Logger.info('JP Cabinet PRO loaded (dev scaffold)')
        rescue StandardError => e
          warn "[JP Cabinet PRO] Load failed: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
          raise
        end

        def register_ui
          # Placeholder: native toolbar/menu/context integration added in Phase 9.
          # Commands registered centrally; UI hooks wired here without decorative-only actions.
          Commands::Registry.register_defaults
        end
      end
    end
  end
end

JPCabinetPro::Bootstrap::Loader.load!
