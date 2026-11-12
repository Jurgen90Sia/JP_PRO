# frozen_string_literal: true

module JPCabinetPro
  module Nesting
    # Real 2D rectangular nesting required (MaxRects, Guillotine, BAF, BSSF, rotation/grain/kerf/trim).
    # This is a non-functional scaffold; no fabricated utilization results.
    class Optimizer
      STRATEGIES = %w[maxrects guillotine best_area_fit best_short_side_fit].freeze

      def plan(_parts, _sheets, strategy: 'maxrects', **_opts)
        raise NotImplementedError, 'Nesting engine not implemented; validation required before reporting results' unless implemented?
        { placements: [], utilization: nil, validated: false, strategy: strategy }
      end

      def implemented?
        false
      end
    end
  end
end
