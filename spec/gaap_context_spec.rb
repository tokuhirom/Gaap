require 'minitest/unit'
require 'minitest/autorun'
require 'rack/test'
require 'gaap'

class TestGaapContext < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def app
    dispatcher = Gaap::Dispatcher.new do
      get '/uri_for' do
        render_json({:uri_a => uri_for('/foo')})
      end
    end
    Gaap::Handler.new(Gaap::Context, dispatcher)
  end

  def test_uri_for
    get 'http://mixi.jp/uri_for'
    assert_equal 200, last_response.status
    assert_equal({'uri_a' => 'http://mixi.jp/foo'}, JSON.parse(last_response.body))
  end
end
