# frozen_string_literal: true

require_relative '../nesting/optimizer'

module JPCabinetPro
  module Commands
    # Prototype nesting command. Validates placement geometry via Optimizer; no UI/manual ops.
    class PlanNesting
      Result = Struct.new(:ok, :errors, :nesting, keyword_init: true)

      def initialize(optimizer: nil)
        @optimizer = optimizer || JPCabinetPro::Nesting::Optimizer.new
      end

      def execute(parts:, sheets:, strategy: 'maxrects')
        errors = []
        errors << 'sheets required' if sheets.nil? || (sheets.respond_to?(:empty?) && sheets.empty?)
        errors << 'parts required' if parts.nil? || (parts.respond_to?(:empty?) && parts.empty?)
        return Result.new(ok: false, errors: errors) unless errors.empty?

        nesting = @optimizer.plan(parts, sheets, strategy: strategy)
        Result.new(ok: nesting[:ok] != false, errors: nesting[:error] ? [nesting[:error]] : [], nesting: nesting)
      rescue StandardError => e
        Result.new(ok: false, errors: [e.message])
      end
    end
  end
end
