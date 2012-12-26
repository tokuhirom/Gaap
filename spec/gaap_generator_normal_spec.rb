require 'gaap/generator'
require 'minitest/unit'
require 'minitest/autorun'
require 'tmpdir'
require 'rack'
require 'rack/test'

class TestGaapGeneratorNormal < MiniTest::Unit::TestCase
  def test_normal
    orig_pwd = Dir::getwd
    Dir::mktmpdir {|dir|
      Dir.chdir dir

      Gaap::Generator.new().run(['Foo'])

      assert File.file?('admin.ru')
      assert File.file?('web.ru')

      # test admin
      test_app = Proc.new {|ru|
        app, option = Rack::Builder.parse_file(ru)
        assert app
        browser = Rack::Test::Session.new(Rack::MockSession.new(app))
        browser.get '/'
        assert_equal 200, browser.last_response.status
        assert_match %r{<html>}, browser.last_response.body
      }

      test_app.('admin.ru')
      test_app.('web.ru')

      Dir.chdir orig_pwd # back to original
    }
  end
end

