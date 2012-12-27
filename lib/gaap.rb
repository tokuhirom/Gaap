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
    def initialize(context_class, dispatcher, container_class=Container)
      @context_class   = context_class
      @dispatcher      = dispatcher
      @container_class = container_class
    end

    # handler method for rack.
    def call(env)
      @container_class.scope {
        app = @context_class.new(env)
        res = @dispatcher.dispatch(app)
        if res.kind_of?(Rack::Response)
          return res.finish()
        elsif res.instance_of?(Array)
          return res
        else
          throw "Bad response : " + res.inspect
        end
      }
    end
  end

  class HTMLEncodedString
    HTML_ENCODED = { '&' => '&amp;',  '>' => '&gt;',   '<' => '&lt;', '"' => '&quot;', "'" => '&#39;' }

    def self.mark_raw(string)
      string.is_a?(HTMLEncodedString) ? string : HTMLEncodedString.new(string)
    end

    def self.encode(string)
      string.is_a?(HTMLEncodedString) ? string : HTMLEncodedString.new(string.to_s.gsub(/[&"'><]/, HTML_ENCODED))
    end

    def initialize(string)
      @string = string
    end

    def to_s
      @string
    end

    def +(s)
      if s.is_a?(HTMLEncodedString)
        # HTMLEncodedString + HTMLEncodedString
        @string += s
      else
        # HTMLEncodedString + String, etc.
        throw "Do not concat HTMLEncodedString with other object. Use to_s or HTMLEncodedString.mark_raw first."
      end
    end
  end

  class Eruby < Erubis::Eruby
    include Erubis::PercentLineEnhancer

    def add_expr(src, code, indicator)
      case indicator
      when '='
        @escape ? add_expr_literal(src, code) : add_expr_escaped(src, code)
      when '=='
        throw "Do not use ==. Use 'mark_raw' function instead."
      when '==='
        add_expr_debug(src, code)
      end
    end

    def escaped_expr(code)
      return "Gaap::HTMLEncodedString.encode((#{code.strip})).to_s()"
    end

    def mark_raw(string)
      Gaap::HTMLEncodedString.mark_raw(string)
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

    attr_accessor :args

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
    def mark_raw(string)
      Gaap::HTMLEncodedString.mark_raw(string)
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
    def render(filename)
      src = File.read(File.join(view_directory, filename))
      eruby = Eruby.new(src, :bufvar => '@_out_buf')
      html = self.instance_eval do
        eval(eruby.src, binding(), filename)
      end
      return create_response(
        [html],
        200,
        {'Content-Type' => html_content_type()}
      )
    end

    @@_wrapper_block_counter = 0
    def wrapper_block(&block)
      @@_wrapper_block_counter += 1
      begin
        retval = block.('@_out_buf_inner' + @@_wrapper_block_counter.to_s)
      ensure
        @@_wrapper_block_counter -= 1
      end
      return retval
    end

    def wrapper(_filename, &_block)
      wrapper_block {|_bufvar|
        _src = File.read(File.join(view_directory, _filename))
        _eruby = Eruby.new(_src, :bufvar => _bufvar)
        # eruby._out_buf = @_out_buf
        # eruby.params = @params
        # eruby.view_directory = @view_directory
        _orig = @_out_buf
        _html = self.instance_eval do
          _orig = @_out_buf
          begin
            @_out_buf = ''
            eval(_eruby.src, binding(), _filename)
          ensure
            @_out_buf = _orig
          end
        end
        @_out_buf = _orig + _html
      }
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

    # Get a path to location
    def uri_for(url)
      return URI.join(@request.url, url).to_s
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
      create_response(JSON.generate(dat), 200, {'Content-Type' => 'application/json;charset=utf-8'})
    end
  end

  class Container
    @@instances = {}

    def self.scope(&block)
      container = nil
      retval = nil
      begin
        container = self.new()
        @@instances[self] = container
        retval = block.(container)
      ensure
        @@instances.delete(self)
        container.destroy
      end
      return retval
    end

    def self.instance
      @@instances[self]
    end

    def destroy
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
    # router = Gaap::Dispatcher.new {
    #   get '/' do
    #     ...
    #   end
    #   get '/foo' do
    #     ...
    #   end
    # }
    def initialize(&block)
      @router = RouterSimple::Router.new()
      if block_given?
        self.instance_eval &block
      end
    end

    def load_controllers(directory)
      Dir["#{directory}/**/*.rb"].each do |f|
        self.instance_eval File.read(f), f
      end
      return self # chain method
    end

    # Dispatch request
    # You can overwrite this method in your dispatcher class.
    #
    # @return Response object
    def dispatch(context)
      dest, args, method_not_allowed = self.match(context.req.request_method, context.req.path_info)

      if dest
        context.args = args
        context.instance_eval &dest[:block]
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
    def get(path, &block)
      connect(['GET', 'HEAD'], path, &block)
    end

    # Add a route as 'POST' only.
    #
    # @params [String, Regexp] path        Request path pattern
    # @params [Class]          dest_class  Destination class.
    # @params [Symbol]         dest_method Destination method.
    def post(path, &block)
      connect(['POST'], path, &block)
    end

    # Add a route.
    #
    # @params [Array, String, Nil] http_method       HTTP Method
    # @params [String, Regexp]     path              Request path pattern
    # @params [Class]              dest_class        Destination class.
    # @params [Symbol]             dest_method       Destination method.
    def connect(http_method, path, &block)
      @router.register(http_method, path, {
        :block       => block,
        :http_method => methods,
      })
    end
  end
end
