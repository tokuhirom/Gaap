require 'minitest/unit'
require 'minitest/autorun'
require 'gaap'

class TestContainer < MiniTest::Unit::TestCase
  class DBI
    @@initialized = 0
    @@disconnected = 0
    def initialize
      @@initialized += 1
    end
    def disconnect
      @@disconnected += 1
    end
    def self.initialized
      @@initialized
    end
    def self.disconnected
      @@disconnected
    end
  end

  def test_index
    container_class = Class.new(Gaap::Container) do
      def dbh
        @dbh ||= DBI.new()
      end
      def destroy
        if @dbh
          @dbh.disconnect
        end
      end
    end
    ret = container_class.scope {|container|
      assert_equal container, container_class.instance
      d1 = container.dbh
      d2 = container.dbh
      assert_equal d1, d2
      5963
    }
    assert_equal 5963, ret
    assert_equal 1, DBI.initialized
    assert_equal 1, DBI.disconnected
  end
end
