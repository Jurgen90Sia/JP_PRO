# frozen_string_literal: true

require_relative '../report/generator'

module JPCabinetPro
  module Commands
    # Prototype report generation from canonical snapshot.
    class GenerateReport
      Result = Struct.new(:ok, :errors, :report, :html, keyword_init: true)

      def initialize(generator: nil)
        @generator = generator || JPCabinetPro::Report::Generator.new
      end

      def execute(snapshot:, options: {})
        r = @generator.generate(snapshot, options)
        Result.new(ok: r.ok, errors: r.errors || [], report: r.report, html: r.html)
      rescue StandardError => e
        Result.new(ok: false, errors: [e.message])
      end
    end
  end
end
