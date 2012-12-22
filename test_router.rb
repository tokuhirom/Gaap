require './router.rb'
require 'minitest/spec'
require 'minitest/autorun'

describe Router, '#xxx' do
    it 'returns nil when there is no registered pattern' do
        router = Router.new()
        assert_equal router.match('/'), nil
    end

    it 'matches / when registered /' do
        router = Router.new()
        router.register('/', 4)
        assert_equal router.match('/'), [4, {}]
    end

    it 'matches /json when registered /json' do
        router = Router.new()
        router.register('/', 2)
        router.register('/json', 4)
        assert_equal router.match('/json'), [4, {}]
    end

    it 'matches /dankogai when registered /:name' do
        router = Router.new()
        router.register('/:name', 4)
        assert_equal router.match('/dankogai'), [4, {'name' => 'dankogai'}]
    end

    it 'matches /dankogai/4 when registered /:name/:entry_id' do
        router = Router.new()
        router.register('/:name/:entry_id', 4)
        assert_equal router.match('/dankogai/4'), [4, {'name' => 'dankogai', 'entry_id' => '4'}]
    end

    it 'does not match /dankogai/4 when registered /:name' do
        router = Router.new()
        router.register('/:name', 4)
        assert_equal router.match('/dankogai/4'), nil
    end

    it 'supports /foo/*name' do
        router = Router.new()
        router.register('/foo/*name', 8)
        assert_equal router.match('/foo/jfsdlkaf/jajkdlsfj'), [8, {'name' => 'jfsdlkaf/jajkdlsfj'}]
    end
end
