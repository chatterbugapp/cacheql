require "test_helper"

class CacheQLTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::CacheQL::VERSION
  end
end
