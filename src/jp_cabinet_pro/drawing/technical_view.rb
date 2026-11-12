# frozen_string_literal: true

module JPCabinetPro
  module Drawing
    # Technical view generation (scaffold). Real vector/projection requires SketchUp/runtime exporters.
    # This module produces a deterministic view model from canonical parts for downstream render/export.
    class TechnicalView
      View = Struct.new(:type, :parts, :dimensions, :scale, :revision, keyword_init: true)

      def generate(parts:, cabinet_params:, view_type: :front, scale: '1:10', revision: 1)
        dims = {
          width_mm: cabinet_params[:width_mm],
          height_mm: cabinet_params[:height_mm],
          depth_mm: cabinet_params[:depth_mm]
        }
        View.new(
          type: view_type,
          parts: project_parts(parts, view_type),
          dimensions: dims,
          scale: scale,
          revision: revision
        ).to_h
      end

      private

      def project_parts(parts, view_type)
        # Placeholder projection metadata; native implementation must compute true 2D projections.
        parts.map do |p|
          {
            part_id: p[:part_id] || p[:id],
            role: p[:role],
            label: p[:name] || p[:role],
            projected: projection_for(p, view_type),
            size_kind: 'nominal'
          }
        end
      end

      def projection_for(p, _view_type)
        { w: p[:width_mm], h: p[:height_mm], t: p[:thickness_mm] }
      end
    end
  end
end
