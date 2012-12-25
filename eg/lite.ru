require 'gaap/lite'

run Gaap::Lite.app {
    get '/' do
        render_json({"x" => 'Y'})
    end
}

