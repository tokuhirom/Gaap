require "bundler/gem_tasks"
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.pattern = "spec/*_spec.rb"
end

# -------------------------------------------------------------------------
# Get resources

begin
  url = 'http://code.jquery.com/jquery-1.8.3.min.js'
  basename = url.gsub(/.*\//, '')

  file :refresh_jquery do
    require 'httpclient'
    FileUtils.mkdir_p "resources/js/"
    h = HTTPClient.new
    html = h.get_content(url)
    File.write("resources/js/#{basename}", html)
  end
end

task :refresh_resource, [:refresh_jquery]
