require 'test/unit'
require 'rack/test'
require 'rack'

class LiteTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    app, options = Rack::Builder.parse_file('eg/lite.ru')
    return app
  end

  def test_it_says_hello_world
    get '/'
    assert last_response.ok?
    assert_equal '{"x":"Y"}', last_response.body
  end
end
