# frozen_string_literal: true

# JP Cabinet PRO - SketchUp Extension Bootstrap
# Target: SketchUp 2021-2026 (Windows initially). Units: mm internally.

require 'sketchup.rb'
require 'extensions.rb'

module JPCabinetPro
  EXTENSION_ID      = 'jp_cabinet_pro'.freeze
  EXTENSION_NAME    = 'JP Cabinet PRO'.freeze
  EXTENSION_VERSION = '0.1.0-dev'.freeze

  unless defined?(@extension)
    path = File.join(__dir__, 'src', 'jp_cabinet_pro', 'bootstrap', 'loader.rb')
    @extension = SketchupExtension.new(EXTENSION_NAME, path)
    @extension.description = 'Parametric cabinet design, BOM, nesting, drawings, and CNC export (original implementation).'
    @extension.version     = EXTENSION_VERSION
    @extension.creator     = 'JP Cabinet PRO'
    @extension.copyright   = '2026 JP Cabinet PRO'
    Sketchup.register_extension(@extension, true)
  end
end
