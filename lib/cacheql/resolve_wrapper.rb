module CacheQL
  class ResolveWrapper
    def initialize(resolver_func)
      @resolver_func = resolver_func
    end

    def __getobj__
      @resolver_func
    end

    # Resolve function level caching!
    def call(obj, args, ctx)
      cache_key = [CacheQL::Railtie.config.global_key, obj.cache_key, ctx.field.name]
      CacheQL::Railtie.config.cache.fetch(cache_key,
        expires_in: CacheQL::Railtie.config.expires_range.sample.minutes) do
        @resolver_func.call(obj, args, ctx)
      end
    end
  end
end
