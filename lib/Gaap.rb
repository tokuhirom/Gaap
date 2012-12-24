require "Gaap/version"

require 'rack'
require 'json'
require 'erubis'
require 'router_simple'

module Gaap
    class Handler
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

    class Dispatcher
        def initialize(env)
            @request = create_request(env)
        end

        attr_reader :request
        alias :req :request

        def create_request(env)
            Request.new(env)
        end

        def view_directory
            'view'
        end

        def render(filename, params={})
            src = File.read(File.join(view_directory, filename))
            eruby = Erubis::Eruby.new(src)
            html = eruby.result(params)
            return create_response(
                [html],
                200,
                {'Content-Type' => 'text/html; charset=utf-8'}
            )
        end

        def dispatch
            dest, args, method_not_allowed = self.router().match(req.request_method, req.path_info)

            if dest
                dest[:dest_class].new(self, args).send(dest[:dest_method])
            elsif method_not_allowed
                return res_405()
            else
                return res_404()
            end
        end

        def router
            throw "Abstract Method"
        end

        def create_response(*args)
            Response.new(*args)
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

    class Controller
        def initialize(c, args)
            @c    = c
            @args = args
        end

        attr_reader :c
        attr_reader :args

        %w(
            create_response
            create_request
            render_json
            render
            res_404
            res_405
        ).each do |method|
            define_method(method) do |*args|
                @c.send(method, *args)
            end
        end
    end

    class Request < Rack::Request
        def is_post_request
            return request_method() == 'POST'
        end
    end

    class Response < Rack::Response
    end

    class Router
        def initialize(&block)
            @router = RouterSimple::Router.new()
            self.instance_eval &block
        end

        def match(http_method, path_info)
            @router.match(http_method, path_info)
        end

        def get(path, dest_class, dest_method)
            connect(['GET', 'HEAD'], path, dest_class, dest_method)
        end

        def post(path, dest_class, dest_method)
            connect(['POST'], path, dest_class, dest_method)
        end

        def connect(http_method, path, dest_class, dest_method)
            @router.register(http_method, path, {
                :dest_class  => dest_class,
                :dest_method => dest_method,
                :http_method => methods,
            })
        end
    end
end
