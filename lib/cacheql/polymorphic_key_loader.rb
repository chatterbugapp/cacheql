# Based on https://github.com/rmosolgo/graphql-batch-example/blob/master/good_schema/polymorphic_key_loader.rb
module CacheQL
  class PolymorphicKeyLoader < GraphQL::Batch::Loader
    def initialize(model, polymorphic_key)
      @model = model
      @polymorphic_key = polymorphic_key
    end

    def perform(polymorphic_value_sets)
      polymorphic_values = polymorphic_value_sets.flatten.uniq
      records = @model.where(@polymorphic_key => polymorphic_values).to_a

      polymorphic_value_sets.each do |polymorphic_value_set|
        matching_records = records.select do |record|
          polymorphic_value_set.id == record.public_send("#{@polymorphic_key}_id") &&
          polymorphic_value_set.class.name == record.public_send("#{@polymorphic_key}_type")
        end
        fulfill(polymorphic_value_set, matching_records)
      end
    end
  end
end
