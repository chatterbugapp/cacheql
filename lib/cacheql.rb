require "digest/sha"
require "activesupport"
require "activerecord"
require "graphql"
require "graphql-batch"

require "cacheql/version"
require "cacheql/cache_wrapper"
require "cacheql/field_instrumentation"

require "cacheql/association_loader"
require "cacheql/polymorphic_key_loader"
require "cacheql/record_loader"

# Wrap a resolve function to store its value in Rails.cache
# This requires `cache_key` as an instance method on the object (usually on ActiveRecord's or scopes),
module CacheQL
  # Required: Plug in Rails.cache here
  mattr_accessor :cache

  # Bump to bust all GraphQL caches!
  mattr_accessor :global_key
  self.global_key = "#{name}/v1"

  # Expire caches within this minute range
  mattr_accessor :expires_range
  self.expires_range = (90..120).to_a.freeze

  # Only allow this array of fields to be cached for now
  mattr_accessor :fetchable_fields
  self.cacheable_fields = []

  # Query-level caching, for any cacheable_fields
  def self.fetch(cacheable_fields, query, variables, &block)
    document = GraphQL.parse(query)
    cacheables = document.definitions.map { |definition| definition.selections.map(&:name) }.flatten & cacheable_fields

    if cacheables.present?
      cache_key = [global_key, 'result', Digest::SHA256.hexdigest(document.to_query_string + variables.to_s)]
      cache.fetch(cache_key, expires_in: expires_range.sample.minutes) do
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
  CacheQL::CacheWrapper.new(resolver_func)
end
