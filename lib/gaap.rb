require "gaap/version"

require 'rack'
require 'json'
require 'erubis'
require 'router_simple'
require 'uri'

# Gaap - Yet another web application framework
module Gaap
  # Handler class for rack
  class Handler
    # @param [Gaap::Dispatcher] dispatcher_class Dispatcher class object
    def initialize(context_class, dispatcher)
      @context_class    = context_class
      @dispatcher = dispatcher
    end

    def call(env)
      app = @context_class.new(env)
      res = @dispatcher.dispatch(app)
      if res.kind_of?(Rack::Response)
        return res.finish()
      elsif res.instance_of?(Array)
        return res
      else
        throw "Bad response : " + res.inspect
      end
    end
  end

  # Context class for Gaap
  class Context
    # @param env Rack's env
    def initialize(env)
      @request = create_request(env)
    end

    attr_reader :request
    alias :req :request

    # Create new request object from env
    # You can overwrite this method in your dispatcher class.
    #
    # @param env Rack's env
    # @return Gaap::Request object
    def create_request(env)
      Request.new(env)
    end

    # Get a directory contains view files
    # You can overwrite this method in your dispatcher class.
    #
    # @return view file directory
    def view_directory
      'view'
    end

    # Get a default Content-Type for html.
    # You can overwrite this method in your dispatcher class.
    #
    # @return [String] HTML content-type
    def html_content_type
      'text/html; charset=utf-8'
    end

    # Render HTML by template engine.
    # You can overwrite this method in your dispatcher class.
    #
    # Default behaviour is rendering template with Erubis.
    #
    # @param [String] filename template file name in view_directory.
    # @param [Hash]   params   parameters. You can use Kernel#binding.
    # @return [String] rendered result
    def render(filename, params={})
      src = File.read(File.join(view_directory, filename))
      eruby = Erubis::Eruby.new(src)
      html = eruby.result(params)
      return create_response(
        [html],
        200,
        {'Content-Type' => html_content_type()}
      )
    end

    # Create 302 redirect response
    #
    # @param [String] url location URL
    # @return instance of Gaap::Response
    def redirect(url)
      res = create_response()
      res.redirect(URI.join(request.url, url).to_s)
      return res
    end

    # Create Gaap::Response object by arguments.
    # You can overwrite this method in your dispatcher class.
    #
    # @param *args arguments passed to Rack::Response.new()
    # @return instance of Gaap::Response
    def create_response(*args)
      Response.new(*args)
    end

    # Create '404 Not Found' response.
    # You can overwrite this method in your dispatcher class.
    def res_404
      create_response('Not Found', 404, {'Content-Type' => 'text/plain'})
    end

    # Create '405 Method Not Allowed' response.
    # You can overwrite this method in your dispatcher class.
    def res_405
      create_response('Method Not Allowed', 405, {'Content-Type' => 'text/plain'})
    end

    # Render JSON as http response.
    #
    # @params dat data to serialize
    # @return instance of Gaap::Response
    def render_json(dat)
      create_response(dat.to_json(), 200, {'Content-Type' => 'application/json;charset=utf-8'})
    end
  end

  # Controller class for Gaap
  class Controller
    # @param [Gaap::Dispatcher] dispatcher instance of dispatcher
    # @param [Hash]             args       captured arguments by router(optional)
    def initialize(context, args={})
      @context = context
      @args    = args
    end

    attr_reader :context
    attr_reader :args

    # delegate methods
    %w(
          create_response
          create_request
          render_json
          render
          redirect
          res_404
          res_405
    ).each do |method|
      define_method(method) do |*args|
        @context.send(method, *args)
      end
    end
  end

  # Request class, is a Rack::Request.
  class Request < Rack::Request
    def is_post_request
      return request_method() == 'POST'
    end
  end

  # Request class, is a Rack::Response.
  class Response < Rack::Response
  end

  class Dispatcher
    # This method takes block.
    #
    # router = Gaap::Router.new {
    #    get '/',    MyApp::C::Root, :index
    #    get '/foo', MyApp::C::Root, :foo
    # }
    def initialize(&block)
      @router = RouterSimple::Router.new()
      self.instance_eval &block
    end

    # Dispatch request
    # You can overwrite this method in your dispatcher class.
    #
    # @return Response object
    def dispatch(context)
      dest, args, method_not_allowed = self.match(context.req.request_method, context.req.path_info)

      if dest
        dest[:dest_class].new(context, args).send(dest[:dest_method])
      elsif method_not_allowed
        return context.res_405()
      else
        return context.res_404()
      end
    end


    # Match to route.
    #
    # @param [String] http_method REQUEST_METHOD
    # @param [String] path_info   PATH_INFO
    # @return destination         destination method
    # @return captured            captured parameters
    # @return method_not_allowed  true if Method Not Allowed.
    def match(http_method, path_info)
      @router.match(http_method, path_info)
    end

    # Add a route as 'GET' only.
    #
    # @params [String, Regexp] path        Request path pattern
    # @params [Class]          dest_class  Destination class.
    # @params [Symbol]         dest_method Destination method.
    def get(path, dest_class, dest_method)
      connect(['GET', 'HEAD'], path, dest_class, dest_method)
    end

    # Add a route as 'POST' only.
    #
    # @params [String, Regexp] path        Request path pattern
    # @params [Class]          dest_class  Destination class.
    # @params [Symbol]         dest_method Destination method.
    def post(path, dest_class, dest_method)
      connect(['POST'], path, dest_class, dest_method)
    end

    # Add a route.
    #
    # @params [Array, String, Nil] http_method       HTTP Method
    # @params [String, Regexp]     path              Request path pattern
    # @params [Class]              dest_class        Destination class.
    # @params [Symbol]             dest_method       Destination method.
    def connect(http_method, path, dest_class, dest_method)
      @router.register(http_method, path, {
        :dest_class  => dest_class,
        :dest_method => dest_method,
        :http_method => methods,
      })
    end
  end
end
