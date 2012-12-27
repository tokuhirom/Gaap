require 'gaap/lite'

run Gaap::Lite.app {
  context_class.class_eval do
    def view_directory
      'spec/view/'
    end
  end

  get '/' do
      render_json({"x" => 'Y'})
  end

  get '/render' do
    @a=4
    @b=5
    render('sum.erb')
  end
}

