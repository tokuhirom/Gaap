=begin

router.rb - minimalistic path dispatcher

=head1 SYNOPSIS

    router = Router.new
    router.register('/', 'Root')
    router.register('/member/:name', 'Member#detail')
    router.register('/download/*path', 'Download#detail')

    router.match('/')
    # => ('Root', {})

    router.match('/member/dankogai')
    # => ('Member#detail', {"name" => 'dankogai'})

    router.match('/download/growthforecast')
    # => ('Download#detail', {"path" => 'growthforecast'})

=end

class Router
    def initialize
        @patterns = []
    end

    def register(path, info)
        @patterns.push(Route.new(path, info))
    end

    def match(path)
        @patterns.each do |pattern|
            r = pattern.match(path)
            return r if r
        end
        return nil
    end
    def __dump
        @patterns.each do |pattern|
            pattern.__dump
        end
    end

    class Route
        def initialize(path, data)
            @path = path
            @pattern = compile(path)
            @data = data
        end

        def __dump
            puts "#{@path} #{@pattern}"
        end

        def match(path)
            matched = @pattern.match(path)
            if matched
                captures = {}
                matched.names.zip(matched.captures).each {|x|
                    captures[x[0]] = x[1]
                }
                return @data, captures
            else
                return nil
            end
        end

        # compile 'path' pattern to regexp.
        def compile(path)
            if path.kind_of?(Regexp)
                return path
            else
                pattern = Regexp.compile(
                    '\A' + (
                    path.gsub(/[-\[\]{}()+?.,\\^$|#\s]/) {|x|
                        Regexp.escape(x)
                    }
                    .gsub(/:([\w\d]+)/, "(?<\\1>[^\/]*)")
                    .gsub(/\*([\w\d]+)/, "(?<\\1>.*?)")
                    ) + '\z'
                )
                pattern
            end
        end
    end
end

