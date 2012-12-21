require 'rack'
require 'json'

class Gaap
end

class Gaap::Handler
    def initialize(context_class)
        @context_class = context_class
    end

    def call(env)
        $GAAP_CONTEXT = @context_class.new(env)
        res = $GAAP_CONTEXT.dispatch()
        if res.kind_of?(Rack::Response)
            return res.finish()
        elsif res.instance_of?(Array)
            return res
        else
            throw "Bad response : " + res.inspect
        end
    end
end

class Gaap::Web
    def initialize(env)
        @request = create_request(env)
    end

    attr_reader :request
    alias :req :request

    def dispatch
        throw "Abstract method"
    end

    def create_request(env)
        Gaap::Web::Request.new(env)
    end

    def create_response(*args)
        Gaap::Web::Response.new(*args)
    end

    def res_404
        create_response('Not found', 404)
    end

    def render_json(dat)
        create_response(dat.to_json(), 200, {'Content-Type' => 'application/json;charset=utf-8'})
    end
end

class Gaap::Web::Request < Rack::Request
end

class Gaap::Web::Response < Rack::Response
end

if $0 == __FILE__
    module MyApp
        class Web < Gaap::Web
            def dispatch
                case req.path_info
                when '/'
                    create_response(['OK'], 200, {})
                when '/json'
                    render_json({:x => 'y'})
                else
                    res_404()
                end
            end
        end
    end

    handler = Gaap::Handler.new(MyApp::Web)
    p handler.call({'PATH_INFO' => '/'})
    p handler.call({'PATH_INFO' => '/json'})
    p "AH"
end

# TODO: routing
