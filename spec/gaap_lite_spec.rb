require 'test/unit'
require 'rack/test'
require 'rack'

class LiteTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    app, options = Rack::Builder.parse_file('eg/lite.ru')
    return app
  end

  def test_root
    get '/'
    assert_equal 200, last_response.status
    assert_equal '{"x":"Y"}', last_response.body
  end

  def test_render
    get '/render'
    assert_equal 200, last_response.status
    assert_equal "RESULT: 9\n", last_response.body
  end
end
