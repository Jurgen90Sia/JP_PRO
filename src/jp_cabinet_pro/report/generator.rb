# frozen_string_literal: true

require 'json'
require 'time'

module JPCabinetPro
  module Report
    # Production report generator. Consumes canonical snapshot data (same source as model/BOM).
    # Produces structured report and HTML; PDF rendering requires external tooling/runtime (not implemented).
    class Generator
      Result = Struct.new(:ok, :status, :report, :html, :errors, keyword_init: true)

      def generate(snapshot, options = {})
        snap = symbolize(snapshot || {})
        return Result.new(ok: false, status: 'INVALID_SNAPSHOT', errors: ['snapshot_required']) if snap.empty?

        report = build_report(snap, options)
        html = to_html(report)
        Result.new(ok: true, status: 'OK', report: report, html: html, errors: [])
      rescue StandardError => e
        Result.new(ok: false, status: 'ERROR', errors: [e.message])
      end

      def to_html(report)
        r = symbolize(report)
        <<~HTML
          <!doctype html>
          <html lang="en">
          <head>
            <meta charset="utf-8"/>
            <title>JP Cabinet PRO Report</title>
            <style>
              body{font-family:Arial,sans-serif;margin:24px;color:#222}
              h1,h2{margin:0 0 8px} table{border-collapse:collapse;width:100%;margin:8px 0 16px}
              th,td{border:1px solid #ccc;padding:6px 8px;font-size:12px;text-align:left}
              th{background:#f2f2f2} .meta{font-size:12px;color:#555;margin-bottom:16px}
              .section{margin-bottom:20px} .svg-wrap{border:1px solid #ccc;padding:8px;overflow:auto}
            </style>
          </head>
          <body>
            <h1>JP Cabinet PRO — Production Report</h1>
            <div class="meta">#{meta_html(r)}</div>
            #{section('Project / Cabinet', kv_table(r[:project] || {}))}
            #{section('Parameters', kv_table(r[:params] || {}))}
            #{section('Fronts / Doors', rows_table(r[:fronts] || []))}
            #{section('Drawers', drawers_section(r[:drawers] || []))}
            #{section('Hardware', rows_table(r[:hardware] || []))}
            #{section('Cut List', rows_table(r[:cutlist] || []))}
            #{section('Materials', rows_table(material_rows(r[:materials] || {})))}
            #{section('Edge Banding', rows_table(r[:edge_banding] || []))}
            #{section('Nesting', nesting_section(r[:nesting]))}
            #{section('Technical View', kv_table(view_summary(r[:view] || {})))}
            #{view_svg_section(r[:view_svg])}
            <div class="meta">Page 1 of 1 (HTML scaffold). PDF/DXF rendering, true projections, barcodes and multi-page layouts not generated.</div>
          </body>
          </html>
        HTML
      end

      private

      def build_report(snap, options)
        meta = snap[:metadata] || {}
        {
          generated_at: Time.now.utc.iso8601,
          project: {
            project_id: snap[:project_id],
            assembly_id: snap[:assembly_id],
            revision: snap[:revision],
            snapshot_version: snap[:snapshot_version],
            created_at: snap[:created_at]
          }.compact,
          params: snap[:params] || {},
          bom: snap[:bom] || [],
          cutlist: snap[:cutlist] || [],
          materials: snap[:materials] || {},
          edge_banding: snap[:edge_banding] || [],
          nesting: snap[:nesting],
          view: snap[:view],
          view_svg: snap[:view_svg],
          fronts: snap[:fronts] || meta[:fronts] || [],
          drawers: snap[:drawers] || meta[:drawers] || [],
          hardware: snap[:hardware] || meta[:hardware] || [],
          options: options || {},
          notes: ['HTML scaffold report generated from canonical snapshot. PDF/A4-A0 layouts, barcodes and true projections not rendered.']
        }
      end

      def meta_html(r)
        p = r[:project] || {}
        "Generated: #{esc(r[:generated_at])} | Assembly: #{esc(p[:assembly_id])} | Revision: #{esc(p[:revision])}"
      end

      def section(title, body)
        %(<div class="section"><h2>#{esc(title)}</h2>#{body}</div>)
      end

      def kv_table(hash)
        return '<p>—</p>' if hash.nil? || hash.empty?
        rows = hash.map { |k, v| "<tr><th>#{esc(k)}</th><td>#{esc(val(v))}</td></tr>" }.join
        "<table>#{rows}</table>"
      end

      def rows_table(rows)
        arr = Array(rows)
        return '<p>—</p>' if arr.empty?
        cols = arr.flat_map { |r| (r || {}).keys }.uniq
        head = cols.map { |c| "<th>#{esc(c)}</th>" }.join
        body = arr.map do |r|
          "<tr>#{cols.map { |c| "<td>#{esc(val((r || {})[c]))}</td>" }.join}</tr>"
        end.join
        "<table><thead><tr>#{head}</tr></thead><tbody>#{body}</tbody></table>"
      end

      def drawers_section(drawers)
        arr = Array(drawers)
        return '<p>—</p>' if arr.empty?
        summary = arr.map do |d|
          box = d[:box] || d['box'] || {}
          front = d[:front] || d['front'] || {}
          {
            index: d[:index] || d['index'],
            front_role: front[:role] || front['role'],
            front_w: front[:width_mm] || front['width_mm'],
            front_h: front[:height_mm] || front['height_mm'],
            box_w: box[:width_mm] || box['width_mm'],
            box_h: box[:height_mm] || box['height_mm'],
            box_d: box[:depth_mm] || box['depth_mm'],
            parts_count: (d[:parts] || d['parts'] || []).length
          }
        end
        rows_table(summary)
      end

      def material_rows(materials)
        m = materials.is_a?(Hash) ? materials : {}
        net = Array(m[:net])
        gross = Array(m[:gross])
        net.map do |n|
          g = gross.find { |x| x[:material_id] == n[:material_id] && x[:thickness_mm] == n[:thickness_mm] } || {}
          { material_id: n[:material_id], thickness_mm: n[:thickness_mm], net_area_mm2: n[:area_mm2], gross_area_mm2: g[:area_mm2], waste_factor: m[:waste_factor] }
        end
      end

      def view_summary(view)
        v = view.is_a?(Hash) ? view : {}
        { type: v[:type], scale: v[:scale], revision: v[:revision], status: v[:status], parts: (v[:parts] || []).length }
      end

      def nesting_section(nesting)
        return '<p>—</p>' if nesting.nil? || nesting == {}
        n = nesting.is_a?(Hash) ? nesting : {}
        summary = {
          ok: n[:ok], strategy: n[:strategy], validated: n[:validated],
          utilization: n[:utilization], sheets_used: (n[:sheets_used] || []).length,
          placements: (n[:placements] || []).length, unplaced: (n[:unplaced] || []).length,
          cut_length_mm: n[:cut_length_mm], cut_length_status: n[:cut_length_status]
        }.compact
        out = kv_table(summary)
        placements = Array(n[:placements]).map do |p|
          { sheet_id: p[:sheet_id], part_id: p[:part_id], x: p[:x], y: p[:y], w: p[:w], h: p[:h], rotated: p[:rotated], validated: p[:validated] }
        end
        out + '<h3>Placements</h3>' + rows_table(placements)
      end

      def view_svg_section(svg)
        return '' if svg.nil? || svg.to_s.strip.empty?
        %(<div class="section"><h2>Technical Drawing (SVG scaffold)</h2><div class="svg-wrap">#{svg}</div></div>)
      end

      def symbolize(obj)
        case obj
        when Hash then obj.each_with_object({}) { |(k, v), o| o[k.to_sym] = symbolize(v) }
        when Array then obj.map { |v| symbolize(v) }
        else obj
        end
      end

      def val(v)
        case v
        when Hash, Array then JSON.generate(v)
        when nil then ''
        else v.to_s
        end
      end

      def esc(s)
        s.to_s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;').gsub('"', '&quot;')
      end
    end
  end
end
