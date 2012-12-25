require 'gaap'
require 'minitest/unit'
require 'minitest/autorun'

class MyApp; end
class MyApp::C; end
class MyApp::C::Root
  def index; end
  def json; end
  def create; end
end
class MyApp::C::Foo
  def index; end
end

class TestDispatcher3 < MiniTest::Unit::TestCase
  def test_router
    router = Gaap::Dispatcher.new {
      get  '/',       MyApp::C::Root, :index
      get  '/json',   MyApp::C::Root, :json
      get  '/foo/',   MyApp::C::Foo,  :index
      post '/create', MyApp::C::Root, :create
    }
    assert router.match('GET', '/')
    assert router.match('GET', '/json')
    assert router.match('GET', '/foo/')
  end
end
