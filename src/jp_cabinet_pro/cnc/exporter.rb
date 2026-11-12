# frozen_string_literal: true

module JPCabinetPro
  module Cnc
    # Adapter-based export architecture. Generic DXF/CSV != verified CNC program.
    # Machine-specific output requires documented config/coords/tools and real validation.
    class Exporter
      def export_generic_dxf(_snapshot)
        { ok: false, status: 'NOT_IMPLEMENTED', note: 'Generic DXF not generated' }
      end

      def export_generic_csv(cutlist)
        require 'csv'
        return '' unless cutlist && !cutlist.empty?
        CSV.generate do |csv|
          csv << cutlist.first.keys
          cutlist.each { |row| csv << row.values }
        end
      end

      def export_machine(_snapshot, _profile)
        { ok: false, status: 'UNVERIFIED', note: 'Machine-specific postprocessor requires verified specs and validation' }
      end
    end
  end
end
