# frozen_string_literal: true

module JPCabinetPro
  module Drawing
    # Technical view generation. Produces deterministic view models and basic SVG (vector) output.
    # True projected geometry from SketchUp entities, dimensioning/layout engines, and PDF/DXF export
    # require further implementation and runtime validation.
    class TechnicalView
      SUPPORTED = %i[front rear left right top bottom isometric exploded panel].freeze
      PAPER = {
        'A4' => [210.0, 297.0], 'A3' => [297.0, 420.0], 'A2' => [420.0, 594.0],
        'A1' => [594.0, 841.0], 'A0' => [841.0, 1189.0]
      }.freeze

      def generate(parts:, cabinet_params:, view_type: :front, scale: '1:10', revision: 1)
        vt = view_type.to_sym
        raise ArgumentError, "unsupported view_type: #{view_type}" unless SUPPORTED.include?(vt)
        dims = {
          width_mm: cabinet_params[:width_mm].to_f,
          height_mm: cabinet_params[:height_mm].to_f,
          depth_mm: cabinet_params[:depth_mm].to_f
        }
        projected = project_parts(parts || [], vt)
        {
          type: vt,
          parts: projected,
          dimensions: dims,
          scale: scale,
          revision: revision,
          status: 'view_model_svg_scaffold'
        }
      end

      # Generates a simple SVG representation (vector). Schematic bounding/part rectangles with labels;
      # not a full projected drawing from SketchUp geometry.
      def to_svg(view_model, paper: 'A4', title: 'JP Cabinet PRO', orientation: :portrait)
        vm = symbolize(view_model)
        size = PAPER[paper.to_s] || PAPER['A4']
        w_mm, h_mm = orientation.to_sym == :landscape ? [size[1], size[0]] : size
        dims = vm[:dimensions] || {}
        cw = (dims[:width_mm] || 0).to_f
        ch = (dims[:height_mm] || 0).to_f
        margin = 20.0
        draw_w = [w_mm - 2 * margin, 10.0].max
        draw_h = [h_mm - 2 * margin - 30.0, 10.0].max
        scale = [draw_w / [cw, 1.0].max, draw_h / [ch, 1.0].max].min
        ox = margin + (draw_w - cw * scale) / 2.0
        oy = margin + (draw_h - ch * scale) / 2.0

        parts = vm[:parts] || []
        rects = parts_svg(parts, ox, oy, scale, ch)
        dim_lines = overall_dimensions_svg(cw, ch, ox, oy, scale)
        title_block = title_block_svg(w_mm, h_mm, margin, title, vm)

        <<~SVG
          <?xml version="1.0" encoding="UTF-8"?>
          <svg xmlns="http://www.w3.org/2000/svg" width="#{w_mm}mm" height="#{h_mm}mm" viewBox="0 0 #{w_mm} #{h_mm}">
            <rect x="0" y="0" width="#{w_mm}" height="#{h_mm}" fill="#ffffff"/>
            <g id="overall-dimensions" stroke="#333" stroke-width="0.3" fill="none">#{dim_lines}</g>
            <g id="parts" stroke="#111" stroke-width="0.4" fill="#f5f5f5">#{rects}</g>
            #{title_block}
          </svg>
        SVG
      end

      private

      def project_parts(parts, view_type)
        parts.map do |p|
          h = p.is_a?(Hash) ? p : p.to_h
          hs = symbolize(h)
          {
            part_id: hs[:part_id] || hs[:id],
            role: hs[:role],
            label: hs[:name] || hs[:role],
            projected: projection_for(hs, view_type),
            size_kind: 'nominal'
          }
        end
      end

      def projection_for(p, view_type)
        w = p[:width_mm].to_f
        h = p[:height_mm].to_f
        t = p[:thickness_mm].to_f
        case view_type
        when :top, :bottom then { w: w, h: t, d: h }
        when :left, :right then { w: t, h: h, d: w }
        else { w: w, h: h, d: t }
        end
      end

      def parts_svg(parts, ox, oy, scale, cabinet_h)
        # Schematic: draw each part as a labeled rect stacked by index (not true assembly projection).
        y_cursor = oy
        parts.each_with_index.map do |p, i|
          pr = p[:projected] || {}
          pw = (pr[:w] || 0).to_f * scale
          ph = [(pr[:h] || 0).to_f * scale, 2.0].max
          # clamp width to visible
          pw = [pw, 5.0].max
          x = ox
          y = y_cursor
          label = esc("#{p[:label] || p[:role] || 'part'} (#{fmt(pr[:w])}x#{fmt(pr[:h])})")
          y_cursor += ph + 1.5
          %(<g><rect x="#{r3(x)}" y="#{r3(y)}" width="#{r3(pw)}" height="#{r3(ph)}"/><text x="#{r3(x + 2)}" y="#{r3(y + [ph * 0.7, 4.0].min)}" font-size="3" fill="#111" stroke="none">#{label}</text></g>)
        end.join
      end

      def overall_dimensions_svg(cw, ch, ox, oy, scale)
        return '' if cw <= 0 || ch <= 0
        x2 = ox + cw * scale
        y2 = oy + ch * scale
        wlabel = esc("#{fmt(cw)} mm")
        hlabel = esc("#{fmt(ch)} mm")
        <<~DIM.gsub("\n", '')
          <line x1="#{r3(ox)}" y1="#{r3(oy - 5)}" x2="#{r3(x2)}" y2="#{r3(oy - 5)}"/>
          <text x="#{r3((ox + x2) / 2)}" y="#{r3(oy - 6)}" font-size="3.5" text-anchor="middle" fill="#111" stroke="none">#{wlabel}</text>
          <line x1="#{r3(ox - 5)}" y1="#{r3(oy)}" x2="#{r3(ox - 5)}" y2="#{r3(y2)}"/>
          <text x="#{r3(ox - 6)}" y="#{r3((oy + y2) / 2)}" font-size="3.5" text-anchor="middle" fill="#111" stroke="none" transform="rotate(-90 #{r3(ox - 6)} #{r3((oy + y2) / 2)})">#{hlabel}</text>
        DIM
      end

      def title_block_svg(w_mm, h_mm, margin, title, vm)
        y = h_mm - margin
        rev = vm[:revision] || 1
        type = vm[:type] || 'view'
        scale = vm[:scale] || '1:10'
        %(<g id="title-block" stroke="#333" stroke-width="0.3" fill="none">) +
          %(<rect x="#{margin}" y="#{y - 12}" width="#{w_mm - 2 * margin}" height="12"/>) +
          %(<text x="#{margin + 2}" y="#{y - 4}" font-size="4" fill="#111" stroke="none">#{esc(title)} | #{esc(type.to_s)} | #{esc(scale.to_s)} | rev #{esc(rev.to_s)}</text>) +
          %(</g>)
      end

      def symbolize(obj)
        case obj
        when Hash then obj.each_with_object({}) { |(k, v), o| o[k.to_sym] = symbolize(v) }
        when Array then obj.map { |v| symbolize(v) }
        else obj
        end
      end

      def esc(s)
        s.to_s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;').gsub('"', '&quot;')
      end

      def fmt(v)
        f = v.to_f
        (f % 1.0).zero? ? f.to_i.to_s : format('%.2f', f)
      end

      def r3(v)
        (v.to_f * 1000).round / 1000.0
      end
    end
  end
end
