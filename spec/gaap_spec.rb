require 'gaap'
require 'minitest/unit'
require 'minitest/autorun'

module MyApp2
  class C < Gaap::Controller
  end

  class C::Root < C
    def index
      create_response(['OK'], 200, {})
    end
    def json
      render_json({:x => 'y'})
    end
    def create
      render_json({:p => 'z'})
    end
  end

  class C::Foo < C
    def index
      create_response(['hoge'])
    end
  end

  class C::Tmpl < C
    def index
      render('index.erb', {
      })
    end
  end

  class Dispatcher < Gaap::Dispatcher
    @@router = Gaap::Router.new {
      get  '/',       C::Root, :index
      get  '/json',   C::Root, :json
      get  '/foo/',   C::Foo,  :index
      post '/create', C::Root, :create
      get  '/tmpl/',  C::Tmpl, :index
    }
    def router
      @@router
    end

    def view_directory
      'spec/view/'
    end
  end
end

class TestMeme < MiniTest::Unit::TestCase
  def setup
    @handler = Gaap::Handler.new(MyApp2::Dispatcher)
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

  def test_tmpl
    res = @handler.call({'PATH_INFO' => '/tmpl/', 'REQUEST_METHOD' => 'GET'})
    assert_equal res[0], 200
    assert_equal res[2].body, ["XXX 5\n"]
  end
end

