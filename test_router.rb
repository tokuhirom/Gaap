require './router.rb'

describe Router, '#match' do
    it 'returns nil when there is no registered pattern' do
        router = Router.new()
        router.match('/').should eq(nil)
    end

    it 'matches / when registered /' do
        router = Router.new()
        router.register('/', 4)
        router.match('/').should eq([4, {}])
    end

    it 'matches /json when registered /json' do
        router = Router.new()
        router.register('/', 2)
        router.register('/json', 4)
        router.match('/json').should eq([4, {}])
    end

    it 'matches /dankogai when registered /:name' do
        router = Router.new()
        router.register('/:name', 4)
        router.match('/dankogai').should eq([4, {'name' => 'dankogai'}])
    end

    it 'matches /dankogai/4 when registered /:name/:entry_id' do
        router = Router.new()
        router.register('/:name/:entry_id', 4)
        router.match('/dankogai/4').should eq([4, {'name' => 'dankogai', 'entry_id' => '4'}])
    end

    it 'does not match /dankogai/4 when registered /:name' do
        router = Router.new()
        router.register('/:name', 4)
        router.match('/dankogai/4').should eq(nil)
    end

    it 'supports /foo/*name' do
        router = Router.new()
        router.register('/foo/*name', 8)
        router.match('/foo/jfsdlkaf/jajkdlsfj').should eq([8, {'name' => 'jfsdlkaf/jajkdlsfj'}])
    end
end
