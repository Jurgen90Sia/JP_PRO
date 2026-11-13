# frozen_string_literal: true

module JPCabinetPro
  module Observers
    # Model/entity observer scaffold with recursion protection.
    # Heavy work must be deferred; full invalidation wiring requires runtime validation.
    class AppObserver < (defined?(::Sketchup::ModelObserver) ? ::Sketchup::ModelObserver : Object)
      def initialize
        @suspended = false
      end

      def suspend(&block)
        prev = @suspended
        @suspended = true
        block.call if block
      ensure
        @suspended = prev
      end

      def suspended?
        @suspended
      end

      def onTransactionCommit(_model)
        return if suspended?
        # Placeholder: mark potential staleness for tracked JP cabinets.
      rescue StandardError
        nil
      end

      def onTransactionUndo(_model)
        return if suspended?
      rescue StandardError
        nil
      end

      def onTransactionRedo(_model)
        return if suspended?
      rescue StandardError
        nil
      end
    end

    module Manager
      class << self
        def observer
          @observer ||= AppObserver.new
        end

        def attach(model = nil)
          return false unless defined?(::Sketchup)
          m = model || (::Sketchup.active_model rescue nil)
          return false unless m && m.respond_to?(:add_observer)
          m.add_observer(observer)
          @attached = true
          true
        rescue StandardError
          false
        end

        def attached?
          !!@attached
        end
      end
    end
  end
end
