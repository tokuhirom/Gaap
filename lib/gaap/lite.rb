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

    class Delegator
      def initialize(dispatcher, context_class)
        @dispatcher    = dispatcher
        @context_class = context_class
      end

      attr_accessor :context_class

      %w(get post any).each do |meth|
        define_method(meth) do |*args, &block|
          @dispatcher.send(meth, *args, &block)
        end
      end
    end

    def self.app(&block)
      dispatcher = Gaap::Lite::Dispatcher.new()

      context_class = Class.new(Gaap::Context) do
      end

      delegator = Delegator.new(dispatcher, context_class)
      delegator.instance_eval &block

      return Gaap::Handler.new(context_class, dispatcher)
    end
  end
end


# enable session by default
