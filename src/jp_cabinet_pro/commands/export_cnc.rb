# frozen_string_literal: true

require_relative '../cnc/exporter'

module JPCabinetPro
  module Commands
    # Prototype CNC/generic exports. Machine-specific outputs remain UNVERIFIED.
    class ExportCnc
      Result = Struct.new(:ok, :errors, :export, keyword_init: true)

      def initialize(exporter: nil)
        @exporter = exporter || JPCabinetPro::Cnc::Exporter.new
      end

      def export_csv(cutlist, columns: nil)
        r = @exporter.export_generic_csv(cutlist, columns: columns)
        Result.new(ok: r.ok, errors: r.ok ? [] : [r.note], export: r)
      end

      def export_nesting_dxf(nesting_result, sheets: [])
        r = @exporter.export_generic_dxf(nesting_result, sheets: sheets)
        Result.new(ok: r.ok, errors: r.ok ? [] : [r.note], export: r)
      end

      def export_machine(snapshot, profile)
        r = @exporter.export_machine(snapshot, profile)
        Result.new(ok: r.ok, errors: [r.note], export: r)
      end
    end
  end
end
