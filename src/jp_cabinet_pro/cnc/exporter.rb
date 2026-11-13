# frozen_string_literal: true

require 'json'

module JPCabinetPro
  module Cnc
    # Adapter-based export architecture. Generic DXF/CSV != verified CNC program.
    # Machine-specific output requires documented config/coords/tools and real validation.
    class Exporter
      Result = Struct.new(:ok, :status, :format, :content, :note, keyword_init: true)

      # data: nesting result hash with :placements and :sheets_used context, plus sheet definitions via `sheets:` kwarg
      # Generates simple rectangular outlines per validated placement (and sheet bounds). Minimal DXF structure.
      def export_generic_dxf(nesting_result, sheets: [])
        data = symbolize(nesting_result || {})
        placements = Array(data[:placements])
        sheet_defs = Array(sheets).map { |s| symbolize(s) }
        sheet_map = {}
        sheet_defs.each { |s| sheet_map[s[:id]] = s }

        if placements.empty? && sheet_defs.empty?
          return Result.new(ok: false, status: 'EMPTY', format: 'dxf', content: nil, note: 'No nesting data for DXF')
        end

        content = build_nesting_dxf(placements, sheet_defs, sheet_map)
        Result.new(
          ok: true,
          status: 'OK',
          format: 'dxf',
          content: content,
          note: 'Generic DXF (rectangular outlines from nesting placements); not a verified CNC program'
        )
      rescue StandardError => e
        Result.new(ok: false, status: 'ERROR', format: 'dxf', content: nil, note: e.message)
      end

      def export_generic_csv(cutlist, columns: nil)
        require 'csv'
        rows = Array(cutlist)
        return Result.new(ok: true, status: 'EMPTY', format: 'csv', content: '', note: 'No rows') if rows.empty?

        normalized = rows.map { |r| symbolize(r) }
        cols = columns || normalized.first.keys
        content = CSV.generate do |csv|
          csv << cols
          normalized.each { |row| csv << cols.map { |c| serialize_cell(row[c]) } }
        end
        Result.new(ok: true, status: 'OK', format: 'csv', content: content, note: 'Generic CSV; not a verified CNC program')
      end

      def export_machine(_snapshot, profile)
        Result.new(ok: false, status: 'UNVERIFIED', format: profile, content: nil,
                   note: 'Machine-specific postprocessor requires verified specs, coords, tools, and validation')
      end

      private

      def build_nesting_dxf(placements, sheet_defs, sheet_map)
        out = []
        dxf_header(out)
        out << '2' << 'ENTITIES'
        # draw sheet outlines
        sheet_defs.each do |s|
          w = s[:w] || s[:width_mm] || s[:width]
          h = s[:h] || s[:height_mm] || s[:height]
          next unless w && h
          layer = "SHEET_#{s[:id]}"
          add_rect(out, 0.0, 0.0, w.to_f, h.to_f, layer)
        end
        # draw placements (grouped by sheet; offset not applied - simple layout per coordinates)
        placements.each do |p|
          next unless p[:validated]
          x = p[:x].to_f
          y = p[:y].to_f
          w = p[:w].to_f
          h = p[:h].to_f
          sid = p[:sheet_id]
          layer = "SHEET_#{sid}"
          add_rect(out, x, y, w, h, layer, label: p[:part_id] || p[:instance_id])
        end
        out << '0' << 'ENDSEC'
        out << '0' << 'EOF'
        out.join("\n") + "\n"
      end

      def dxf_header(out)
        out << '0' << 'SECTION'
        out << '2' << 'HEADER'
        out << '9' << '$ACADVER'
        out << '1' << 'AC1009'
        out << '0' << 'ENDSEC'
        out << '0' << 'SECTION'
      end

      def add_rect(out, x, y, w, h, layer, label: nil)
        x2 = x + w
        y2 = y + h
        add_line(out, x, y, x2, y, layer)
        add_line(out, x2, y, x2, y2, layer)
        add_line(out, x2, y2, x, y2, layer)
        add_line(out, x, y2, x, y, layer)
        if label
          add_text(out, x + w * 0.05, y + h * 0.5, [h * 0.08, 2.0].max, layer, label.to_s)
        end
      end

      def add_line(out, x1, y1, x2, y2, layer)
        out << '0' << 'LINE'
        out << '8' << layer.to_s
        out << '10' << fmt(x1)
        out << '20' << fmt(y1)
        out << '30' << '0.0'
        out << '11' << fmt(x2)
        out << '21' << fmt(y2)
        out << '31' << '0.0'
      end

      def add_text(out, x, y, h, layer, text)
        out << '0' << 'TEXT'
        out << '8' << layer.to_s
        out << '10' << fmt(x)
        out << '20' << fmt(y)
        out << '30' << '0.0'
        out << '40' << fmt(h)
        out << '1' << text.to_s
      end

      def fmt(v)
        format('%.4f', v.to_f)
      end

      def symbolize(h)
        return h unless h.is_a?(Hash)
        h.each_with_object({}) { |(k, v), out| out[k.to_sym] = v }
      end

      def serialize_cell(v)
        case v
        when Hash, Array then JSON.generate(v)
        else v
        end
      end
    end
  end
end
