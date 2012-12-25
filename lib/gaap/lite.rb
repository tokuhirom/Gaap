require 'router_simple'
require 'rack'
require 'gaap'

module Gaap
  module Lite
    class Dispatcher
        def initialize
          @router = RouterSimple::Router.new
        end

        def dispatch(c)
          dest, args, method_not_allowed = @router.match(c.req.request_method, c.req.path_info)

          if dest
            controller = Gaap::Controller.new(c, args) 
            return controller.instance_eval &dest
          elsif method_not_allowed
            return c.res_405()
          else
            return c.res_404()
          end
        end

        attr_accessor :args

        def get(path, &block)
          @router.register(['GET', 'HEAD'], path, block)
        end

        def post(path, &block)
          @router.register('POST', path, block)
        end

        def any(path, &block)
          @router.register(nil, path, &block)
        end
    end

    def self.app(&block)
      dispatcher = Gaap::Lite::Dispatcher.new()
      dispatcher.instance_eval &block
      return Gaap::Handler.new(Gaap::Context, dispatcher)
    end
  end
end


# enable session by default
