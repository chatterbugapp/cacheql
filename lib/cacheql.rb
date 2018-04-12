require "digest"

require "graphql"
require "graphql/batch"

require "cacheql/version"
require "cacheql/resolve_wrapper"
require_relative "./cacheql/railtie" if defined? Rails::Railtie

# Wrap a resolve function to store its value in Rails.cache
# This requires `cache_key` as an instance method on the object (usually on ActiveRecord's or scopes),
module CacheQL
  # Query-level caching, for any cacheable_fields
  def self.fetch(cacheable_fields, query, variables, &block)
    document = GraphQL.parse(query)
    cacheables = document.definitions.map { |definition| definition.selections.map(&:name) }.flatten & cacheable_fields

    if cacheables.present?
      cache_key = [CacheQL::Railtie.config.global_key, 'result', Digest::SHA256.hexdigest(document.to_query_string + variables.to_s)]
      cache.fetch(cache_key, expires_in: CacheQL::Railtie.config.expires_range.sample.minutes) do
        block.call(document)
      end
    else
      block.call(document)
    end
  end
end

# Always a hack, but looks nice
# Wrap a resolve func with:
# resolve CacheQL -> { |obj, args, ctx| obj.do_stuff }
def CacheQL(resolver_func)
  CacheQL::ResolveWrapper.new(resolver_func)
end
