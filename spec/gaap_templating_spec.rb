require 'gaap'
require 'minitest/spec'
require 'minitest/autorun'

describe Gaap do
  context_class = Class.new(Gaap::Context) do
    def view_directory
      'spec/view/'
    end
  end
  c = context_class.new({})
  it 'gaap' do
    res = c.render('escape.erb', {
      :a => "<'",
      :b => "<'",
    })
    assert_equal res.body[0], <<-EOF.gsub(/^\s+/, '')
    A:&lt;&#39;
    B:<'
    EOF
  end
end
