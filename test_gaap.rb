require './gaap.rb'
require 'minitest/unit'
require 'minitest/autorun'

module MyApp
    class Web < Gaap::Web; end
    module Web::C; end

    class Web::C::Root
        def index(c)
            c.create_response(['OK'], 200, {})
        end
        def json(c)
            c.render_json({:x => 'y'})
        end
        def create(c)
            c.render_json({:p => 'z'})
        end
    end

    class Web::C::Foo
        def index(c)
            c.create_response(['hoge'])
        end
    end

    class Web < Gaap::Web
        @@router = Gaap::Router.new('MyApp::Web') {
            get  '/',       Web::C::Root, :index
            get  '/json',   Web::C::Root, :json
            get  '/foo/',   Web::C::Foo,  :index
            post '/create', Web::C::Root, :create
        }
        def router
            @@router
        end
    end
end

class TestMeme < MiniTest::Unit::TestCase
    def setup
        @handler = Gaap::Handler.new(MyApp::Web)
    end

    def test_root
        res = @handler.call({'PATH_INFO' => '/', 'REQUEST_METHOD' => 'GET'})
        assert_equal res[0], 200
        assert_equal res[2].body, ['OK']
    end

    def test_root_405
        res = @handler.call({'PATH_INFO' => '/', 'REQUEST_METHOD' => 'POST'})
        assert_equal res[0], 405
        assert_equal res[2].body, ['Method Not Allowed']
    end

    def test_json
        res = @handler.call({'PATH_INFO' => '/json', 'REQUEST_METHOD' => 'GET'})
        assert_equal res[0], 200
        assert_equal res[2].body, ['{"x":"y"}']
    end

    def test_foo
        res = @handler.call({'PATH_INFO' => '/foo/', 'REQUEST_METHOD' => 'GET'})
        assert_equal res[0], 200
        assert_equal res[2].body, ['hoge']
    end

    def test_create
        res = @handler.call({'PATH_INFO' => '/create', 'REQUEST_METHOD' => 'POST'})
        assert_equal res[0], 200
        assert_equal res[2].body, ['{"p":"z"}']
    end
    def test_create_405
        res = @handler.call({'PATH_INFO' => '/create', 'REQUEST_METHOD' => 'GET'})
        assert_equal res[0], 405
        assert_equal res[2].body, ['Method Not Allowed']
    end
end

__END__
