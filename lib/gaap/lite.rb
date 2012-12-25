require 'router_simple'
require 'rack'
require 'gaap'

module Gaap
    module Lite
        def self.app(&block)
            router_class = Class.new do
                def initialize
                    @router = RouterSimple::Router.new
                end

                def match(*args)
                    @router.match(*args)
                end

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
            router = router_class.new()
            dispatcher_class = Class.new(Gaap::Dispatcher) do
                def self.router=(router)
                    @@router = router
                end

                def initialize(env)
                    super(env)
                end

                attr_accessor :args

                def dispatch
                    dest, args, method_not_allowed = @@router.match(req.request_method, req.path_info)

                    if dest
                        @args = args
                        return self.instance_eval &dest
                    elsif method_not_allowed
                        return res_405()
                    else
                        return res_404()
                    end
                end
            end
            router.instance_eval &block
            dispatcher_class.router = router
            return Gaap::Handler.new(dispatcher_class)
        end
    end
end


# enable session by default
