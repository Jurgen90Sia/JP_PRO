# frozen_string_literal: true

module JPCabinetPro
  module Diagnostics
    module Logger
      class << self
        def info(msg)  = log('INFO', msg)
        def warn(msg)  = log('WARN', msg)
        def error(msg) = log('ERROR', msg)

        def log(level, msg)
          line = "[JPCabinetPro][#{level}] #{msg}"
          if defined?(::Sketchup) && ::Sketchup.respond_to?(:status_text)
            # Avoid noisy status bar; keep console/log.
          end
          Kernel.warn(line)
          line
        end
      end
    end
  end
end
