require 'rack'
require 'json'
require 'tilt'
require 'erubis'
require './router'

class Gaap
end

class Gaap::Handler
    def initialize(context_class)
        @context_class = context_class
    end

    def call(env)
        app = @context_class.new(env)
        res = app.dispatch()
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

    def create_request(env)
        Gaap::Web::Request.new(env)
    end

    def render(filename, params)
        src = File.read(filename)
        Erubis::Eruby.new(src)
        html = eruby.result(src)
        return create_response([html], {'Content-Type' => 'text/html; charset=utf-8'}, 200)
    end

    def dispatch
        dest, args = self.router().match(req.path_info)

        if dest
            # Method not allowed
            if dest[:http_method] && !dest[:http_method].any? {|method| method==req.request_method }
                return res_405()
            end
            dest[:dest].(self)
        else
            return res_404()
        end
    end

    def router
        throw "Abstract Method"
    end

    def create_response(*args)
        Gaap::Web::Response.new(*args)
    end

    def res_404
        create_response('Not Found', 404)
    end

    def res_405
        create_response('Method Not Allowed', 405)
    end

    def render_json(dat)
        create_response(dat.to_json(), 200, {'Content-Type' => 'application/json;charset=utf-8'})
    end
end

class Gaap::Web::Request < Rack::Request
end

class Gaap::Web::Response < Rack::Response
end

class Gaap::Router
    def initialize(base, &block)
        @base = base
        @router = Router.new()
        @cache = {}
        self.instance_eval &block
    end

    def match(path_info)
        @router.match(path_info)
    end

    def get(path, dest_class, dest_method)
        connect(path, dest_class, dest_method, ['GET', 'HEAD'])
    end

    def post(path, dest_class, dest_method)
        connect(path, dest_class, dest_method, ['POST'])
    end

    def connect(path, dest_class, dest_method, methods=nil)
        dest = (@cache[dest_class] ||= dest_class.new())
        @router.register(path, {
            :dest        => dest.method(dest_method),
            :http_method => methods,
        })
    end
end

# TODO: template engine
