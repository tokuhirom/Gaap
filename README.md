# Gaap

Gaap is a *straightforward* web application framework for Ruby.

## Features

    * Easy to debug
    * Easy to hack
    * Easy to write

## Installation

Add this line to your application's Gemfile:

    gem 'Gaap'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install Gaap

## Usage

### Gaap

You can write your application class as following:

    require 'gaap'

    module MyApp
        class C; end

        class C::Root
            def index
                render('index.erb', {})
            end
        end

        @@dispatcher = Gaap::Dispatcher.new do
            get '/', C::Root, :index
        end

        class Context < Gaap::Context
        end

        def handler
            Gaap::Handler.new(Context, @@dispatcher)
        end
    end

And you config.ru is:

    require 'myapp'

    run MyApp.handler

### Gaap::Lite

You can write your app.ru as following:

  require 'gaap/lite'
  require 'rack/protection'

  use Rack::Session::Cookie
  use Rack::Protection

  use Gaap::Lite.app do
    context_class.class_eval do
      def view_directory
        'view/'
      end
    end

    get '/' do
      render('index.erb', {})
    end
  end

## FAQ

### How do you use file stored session?

Use [rack-session-file](https://github.com/dayflower/rack-session-file)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
