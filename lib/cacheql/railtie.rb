module CacheQL
  class Railtie < Rails::Railtie
    config.cache = Rails.cache
    config.logger = Rails.logger

    # Bump to bust all GraphQL caches!
    config.global_key = "CacheQL/v1"

    # Expire caches within this minute range
    config.expires_range = (90..120).to_a.freeze

    initializer "cacheql.initialize" do
      require "cacheql/field_instrumentation"
      require "cacheql/polymorphic_key_loader"
      require "cacheql/record_loader"
    end

    initializer "cacheql.initialize_ar" do
      ActiveSupport.on_load(:active_record) do
        require "cacheql/association_loader"
      end
    end
  end
end
