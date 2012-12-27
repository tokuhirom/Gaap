require "bundler/gem_tasks"
require 'rake/testtask'
require 'tempfile'

Rake::TestTask.new do |t|
  t.pattern = "spec/*_spec.rb"
end

# -------------------------------------------------------------------------
# Get resources
def mirror_resource(url)
  puts "retrieve #{url}"
  require 'httpclient'
  h = HTTPClient.new
  html = h.get_content(url)
  basename = url.gsub(/.*\//, '')
  File.write("resources/js/static/#{basename}", html)
end

def resource_task(name, url)
  task name do
    mirror_resource(url)
  end
end

resource_task :jquery,  'http://code.jquery.com/jquery-1.8.3.min.js'
resource_task :sprintf, 'http://sprintf.googlecode.com/files/sprintf-0.7-beta1.js'
resource_task :micro_location, 'https://raw.github.com/cho45/micro-location.js/master/lib/micro-location.js'
resource_task :strftime, 'https://raw.github.com/tokuhirom/strftime-js/master/strftime.js'
resource_task :es5shim, 'https://raw.github.com/kriskowal/es5-shim/master/es5-shim.min.js'

task :bootstrap do
  puts "fetching bootstrap"
  url = 'http://twitter.github.com/bootstrap/assets/bootstrap.zip'
  require 'httpclient'
  h = HTTPClient.new
  content = h.get_content(url)
  t = Tempfile.new('bootstrap')
  t.write(content)
  # -o overwrite all
  # -d destination directory
  system("unzip -o #{t.path} -d ./resources/static/") or raise "Bad unzip: #{$?}"
end

task :resource, [:jquery, :sprintf]
