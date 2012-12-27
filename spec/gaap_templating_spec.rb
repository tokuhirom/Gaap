require 'gaap'
require 'minitest/spec'
require 'minitest/autorun'

describe Gaap do
  context_class = Class.new(Gaap::Context) do
    def view_directory
      'spec/view/'
    end
    attr_accessor :a, :b
  end
  describe 'escape' do
    c = context_class.new({})
    c.a = "<'"
    c.b = "<'"
    it 'gaap' do
      res = c.render('escape.erb')
      assert_equal res.body[0], <<-EOF.gsub(/^\s+/, '')
      A:&lt;&#39;
      B:<'
      EOF
    end
  end

  describe 'wrapper' do
    it 'do' do
      c = context_class.new({})
      c.a = 'XXX'
      res = c.render('wrapper.erb')
      assert_equal res.body[0], <<-EOF.gsub(/^\s+/, '')
      111
      AAAXXX
      BBBXXX
      CCCXXX
      333
      EOF
    end
  end
end
