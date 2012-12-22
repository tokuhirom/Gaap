require './gaap.rb'
require 'minitest/unit'
require 'minitest/autorun'

class MyApp; end
class MyApp::Web; end
class MyApp::Web::C; end
class MyApp::Web::C::Root
    def index; end
    def json; end
    def create; end
end
class MyApp::Web::C::Foo
    def index; end
end

class TestRouter < MiniTest::Unit::TestCase
    def test_router
        router = Gaap::Router.new('MyApp::Web') {
            get  '/',       MyApp::Web::C::Root, :index
            get  '/json',   MyApp::Web::C::Root, :json
            get  '/foo/',   MyApp::Web::C::Foo,  :index
            post '/create', MyApp::Web::C::Root, :create
        }
        assert router.match('/')
        assert router.match('/json')
        assert router.match('/foo/')
    end
end
