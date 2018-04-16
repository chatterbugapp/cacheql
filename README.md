# CacheQL

Need to cache and instrument your GraphQL code in Ruby? Look no further!

This is a collection of utilities for [graphql-ruby](http://graphql-ruby.org)
that were collected from various places on GitHub + docs.

This code was extracted from [Chatterbug](https://chatterbug.com).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cacheql'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cacheql

## Usage

There's four major parts to this gem:

### Cache helpers

Need to cache a single resolve function? Wrap it in `CacheQL`:

``` ruby
resolve CacheQL -> (obj, args, ctx) {
  # run expensive operation
  # this resolve function's result will be cached on obj.cache_key
}
```

Want to cache the entire response after GraphQL has generated it? Try this in
your controller:

``` ruby
def execute
  # other graphql stuff...

  FIELDS = %w(users curriculum)
  render json: CacheQL.fetch(FIELDS, query, variables) { |document|
    YourSchema.execute(
      document: document,
      variables: variables,
      context: { },
      operation_name: params[:operationName]).to_h
  }
end
```

This will cache the entire response when the query includes `FIELDS`.

### Loaders

These are all based off of community-written examples using [graphql-batch](https://github.com/Shopify/graphql-batch).
These will reduce N+1 queries in your GraphQL code.

Batch up `belongs_to` calls:

``` ruby
# when obj has a belongs_to :language

resolve -> (obj, args, ctx) {
  CacheQL::RecordLoader.for(Language).load(obj.language_id)
}
```

Batch up `belongs_to polymorphic: true` calls:

``` ruby
# when obj has a belongs_to :respondable, polymorphic: true

resolve -> (obj, args, ctx) {
  CacheQL::PolymorphicKeyLoader.for(Response, :respondable).load(obj.respondable)
}
```

Batch up entire associations:

``` ruby
# when obj has_many :clozes

resolve -> (obj, args, ctx) {
  CacheQL::AssociationLoader.for(obj.class, :clozes).load(obj)
}
```

### Logging

Want to get your GraphQL fields logging locally? In your controller, add:


``` ruby
around_action :log_field_instrumentation

private

def log_field_instrumentation(&block)
  CacheQL::FieldInstrumentation.log(&block)
end
```

This will then spit out timing logs for each field run during each request.
For example:

```
[CacheQL::Tracing] User.displayLanguage took 7.591ms
[CacheQL::Tracing] User.createdAt took 0.117ms
[CacheQL::Tracing] User.intercomHash took 0.095ms
[CacheQL::Tracing] User.id took 0.09ms
[CacheQL::Tracing] User.friendlyTimezone took 0.087ms
[CacheQL::Tracing] User.utmContent took 0.075ms
[GraphQL::Tracing] User.timezone took 0.048ms
[CacheQL::Tracing] User.email took 0.046ms
[CacheQL::Tracing] User.name took 0.042ms
[CacheQL::Tracing] Query.currentUser took 0.041ms
```

### Instrumentation

This gem includes an instrumenter for [Scout](https://scoutapp.com) that will
show the timing breakdown of each field in your metrics. Assuming you have Scout
setup, add to your schema:


``` ruby
YourSchema = GraphQL::Schema.define do
  instrument :field, CacheQL::FieldInstrumentation.new(ScoutApm::Tracer)
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/chatterbugapp/cacheql.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
