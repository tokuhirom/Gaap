require 'gaap/generator'
require 'minitest/unit'
require 'minitest/autorun'
require 'tmpdir'
require 'rack'
require 'rack/test'
require "bundler"
Bundler.setup
Bundler.require

class TestGaapGeneratorNormal < MiniTest::Unit::TestCase
  def test_normal
    Dir::mktmpdir {|dir|
      Dir.chdir(dir) {
        generator = Gaap::Generator.new()
        generator.run(['Foo'])

        Dir.chdir('Foo') {
          assert File.exists?('Rakefile')
          %w(admin web).each do |type|
            Dir.chdir(type) do
              assert File.file?('config.ru')
              app, option = Rack::Builder.parse_file('config.ru')
              assert app
              browser = Rack::Test::Session.new(Rack::MockSession.new(app))
              browser.get '/'
              assert_equal 200, browser.last_response.status
              assert_match %r{<html>}, browser.last_response.body

              browser.get "/static/js/#{generator.jquery_basename}"
              assert_equal 200, browser.last_response.status
            end
          end
        }
      }
    }
  end

  def test_lite
    Dir::mktmpdir {|dir|
      Dir.chdir(dir) {
        generator = Gaap::Generator.new()
        generator.run(['--lite', 'Foo'])

        Dir.chdir('Foo') {
          assert File.file?('config.ru')
          assert File.exists?('Rakefile')

          # test admin
          test_app = Proc.new {|ru|
            app, option = Rack::Builder.parse_file(ru)
            assert app
            browser = Rack::Test::Session.new(Rack::MockSession.new(app))
            browser.get '/'
            assert_equal 200, browser.last_response.status
            assert_match %r{<html>}, browser.last_response.body

            browser.get "/static/js/#{generator.jquery_basename}"
            assert_equal 200, browser.last_response.status
          }

          test_app.('config.ru')
        }
      }
    }
  end
end

