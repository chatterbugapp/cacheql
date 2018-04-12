# https://github.com/rmosolgo/graphql-ruby/blob/master/lib/graphql/tracing/scout_tracing.rb
# https://github.com/rmosolgo/graphql-ruby/blob/master/guides/fields/instrumentation.md
# http://help.apm.scoutapp.com/#ruby-custom-instrumentation
module CacheQL
  class FieldInstrumentation
    NAME = "graphql.field".freeze

    # For use in an around_action call to log all fields. For example:
    #
    # around_action :log_field_instrumentation
    #
    # def log_field_instrumentation(&block)
    #   CacheQL::FieldInstrumentation.log(Rails.logger, &block)
    # end
    def self.log(logger, &block)
      field_instruments = Hash.new(0)
      ActiveSupport::Notifications.subscribe(NAME) do |*args|
        event = ActiveSupport::Notifications::Event.new(*args)
        field_instruments[event.payload[:label]] += event.duration
      end

      block.call

      ActiveSupport::Notifications.unsubscribe(NAME)
      field_instruments.sort_by(&:last).reverse.each do |field, ms|
        logger.info "[CacheQL::Tracing] #{field} took #{ms.round(3)}ms"
      end
    end

    # instrumenter must respond to #instrument
    # See ScoutApm::Tracer for example
    def initialize(instrumenter)
      @instrumenter = instrumenter
    end

    # Track timing for all fields
    def instrument(type, field)
      # Ignore internal GraphQL types
      if type.name.starts_with?("__")
        field
      else
        label = "#{type.name}.#{field.name}"
        old_resolve_proc = field.resolve_proc

        new_resolve_proc = -> (obj, args, ctx) {
          ActiveSupport::Notifications.instrument(NAME, label: label) do
            @instrumenter.instrument("GraphQL", label) do
              resolved = old_resolve_proc.call(obj, args, ctx)
              resolved
            end
          end
        }

        # Return a copy of `field`, with a new resolve proc
        field.redefine do
          resolve(new_resolve_proc)
        end
      end
    end
  end
end
