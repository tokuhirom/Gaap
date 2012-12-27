require 'gaap'
require 'minitest/unit'
require 'minitest/autorun'

module MyApp2
  class Context < Gaap::Context
    def router
      @@router
    end

    def view_directory
      'spec/view/'
    end
  end

  @@dispatcher = Gaap::Dispatcher.new {
    get  '/' do
      create_response(['OK'], 200, {})
    end
    get  '/json' do
      render_json({:x => 'y'})
    end
    get  '/foo/' do
      create_response(['hoge'])
    end
    post '/create' do
      render_json({:p => 'z'})
    end
    get  '/tmpl/' do
      render('index.erb')
    end
  }
  def self.dispatcher
    @@dispatcher
  end
end

class TestMeme < MiniTest::Unit::TestCase
  def setup
    @handler = Gaap::Handler.new(MyApp2::Context, MyApp2.dispatcher)
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

