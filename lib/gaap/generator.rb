require 'erubis'
require 'fileutils'

module Gaap
  class Generator
    def strip_heredoc(s)
      mindent = s.scan(/^[ \t]*(?=\S)/).min
      indent = mindent.nil? ? 0 : mindent.size
      s.gsub(/^[ \t]{#{indent}}/, '')
    end

    def write_file(path, content)
      FileUtils.mkpath(File.dirname(path))
      File.write(path, strip_heredoc(content))
    end

    def write_file_heredoc(path, content)
      write_file(path, strip_heredoc(content))
    end

    def render(src, params)
      Erubis::Eruby.new(src).result(params)
    end

    def run(argv=ARGV)
      lite = false
      require 'optparse'
      OptionParser.new { |op|
        op.on('--lite') do
          lite = true
        end
      }.parse!(argv)
      if argv.length == 0
        puts "Usage: #{File.basename($0)} project_name"
        exit 0
      end
      proj = argv.shift

      if File.exists?(proj)
        puts "'#{proj}' is already exists."
        exit 1
      end
      Dir::mkdir(proj)
      Dir::chdir proj

      if lite
        run_lite(proj)
      else
        run_normal(proj)
      end
    end

    def run_lite(proj)
      Dir::mkdir('view/')

      write_file_heredoc('config.ru', <<-EOF)
      require 'gaap/lite'
      require 'rack/protection'

      use Rack::Session::Cookie
      use Rack::Protection

      run Gaap::Lite.app() {
        context_class.class_eval do
          def view_directory
            'view/'
          end
        end

        get '/' do
          render('index.erb', {})
        end
      }
      EOF

      write_file_heredoc("view/index.erb", <<-EOF)
      <!doctype html>
      <html>
        <head>
          <met charset="utf-8">
          <title>Application</title>
        </head>
        <body>
          <h1>Application Skelton</h1>
        </body>
      </html>
      EOF
    end

    def run_normal(proj)
      Dir::mkdir('lib')
      Dir::mkdir('view')
      Dir::mkdir("lib/#{proj.downcase}")

      %w(Admin Web).each do |type|
        write_file_heredoc("#{type.downcase}.ru", render(<<-EOF, binding))
        $LOAD_PATH.unshift File.absolute_path('./lib')
        require '<%= proj.downcase %>/<%= type.downcase %>'

        run <%= proj %>::<%= type %>.handler
        EOF

        Dir::mkdir("view/#{type.downcase}")
        write_file_heredoc("view/#{type.downcase}/index.erb", <<-EOF)
        <!doctype html>
        <html>
          <head>
            <met charset="utf-8">
            <title>Application</title>
          </head>
          <body>
            <h1>Application Skelton</h1>
          </body>
        </html>
        EOF

        write_file_heredoc("lib/#{proj.downcase}/#{type.downcase}.rb", render(<<-EOF, binding()))
        require 'gaap'

        module <%= proj %>
          module <%= type %>
            class Context < Gaap::Context
              @@view_directory = File.absolute_path('view/<%= type.downcase %>')
              def view_directory
                @@view_directory
              end
            end

            class C; end

            class C::Root < Gaap::Controller
              def index
                render('index.erb', {})
              end
            end

            @@dispatcher = Gaap::Dispatcher.new do
              get '/', C::Root, :index
            end

            class Context < Gaap::Context
            end

            def self.handler
              Gaap::Handler.new(Context, @@dispatcher)
            end
          end
        end
        EOF
      end
    end
  end
end
