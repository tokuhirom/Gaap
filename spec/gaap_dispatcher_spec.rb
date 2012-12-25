require 'gaap'
require 'minitest/unit'
require 'minitest/autorun'

module MyApp3
  class Context < Gaap::Context
    def view_directory
      'spec/view/'
    end
  end

  class Dispatcher
    def dispatch(c)
      case c.req.path_info
      when '/res_405'
        c.res_405()
      when '/res_404'
        c.res_404()
      when '/render'
        c.render('index.erb', binding())
      else
        throw "Bad."
      end
    end
  end
end

class TestDispatcher < MiniTest::Unit::TestCase
  def setup
    @handler = Gaap::Handler.new(MyApp3::Context, MyApp3::Dispatcher.new())
  end

  def test_res_405
    res = @handler.call({'PATH_INFO' => '/res_405', 'REQUEST_METHOD' => 'POST'})
    assert_equal res[0], 405
    assert_equal res[1]['Content-Type'], 'text/plain'
    assert_equal res[2].body, ['Method Not Allowed']
  end

  def test_res_404
    res = @handler.call({'PATH_INFO' => '/res_404', 'REQUEST_METHOD' => 'POST'})
    assert_equal res[0], 404
    assert_equal res[1]['Content-Type'], 'text/plain'
    assert_equal res[2].body, ['Not Found']
  end

  def test_render
    res = @handler.call({'PATH_INFO' => '/render', 'REQUEST_METHOD' => 'GET'})
    assert_equal res[0], 200
    assert_equal res[1]['Content-Type'], 'text/html; charset=utf-8'
    assert_equal res[2].body, ["XXX 5\n"]
  end
end

