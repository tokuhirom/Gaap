require 'gaap'
require 'minitest/unit'
require 'minitest/autorun'

class TestDispatcher3 < MiniTest::Unit::TestCase
  def test_router
    router = Gaap::Dispatcher.new {
      get  '/' do end
      get  '/json'  do end
      get  '/foo/' do end
      post '/create'  do end
    }
    assert router.match('GET', '/')[0]
    assert router.match('GET', '/json')[0]
    assert router.match('GET', '/foo/')[0]
  end
  def test_load_controllers
    router = Gaap::Dispatcher.new.load_controllers('spec/controllers/')
    assert router.match('GET', '/')[0]
    assert !router.match('GET', '/not_found')[0]
  end
end
