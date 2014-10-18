# -*- encoding : utf-8 -*-

SKETCH_PATH ||= ARGV.shift
SKETCH_ROOT ||= File.dirname(SKETCH_PATH)

require_relative '../jruby_art'
require_relative '../jruby_art/app'

module Processing
  # For use with "bare" sketches that don't want to define a class or methods
  SKETCH_TEMPLATE = <<-EOS
  require 'jruby_art'

  class Sketch < Processing::App
    <% if has_methods %>
    <%= source %>
    <% else %>
    def setup
      <%= source %>
      no_loop
    end
    <% end %>
  end

  Sketch.new(title: 'Bare Sketch')
  EOS

  # This method is the common entry point to run a sketch, bare or complete.
  def self.load_and_run_sketch
    source = read_sketch_source
    has_sketch = !source.match(/^[^#]*< Processing::App/).nil?
    has_methods = !source.match(/^[^#]*(def\s+setup|def\s+draw)/).nil?

    if has_sketch
      load File.join(SKETCH_ROOT, SKETCH_PATH)
      Processing::App.sketch_class.new unless $app
    else
      require 'erb'
      code = ERB.new(SKETCH_TEMPLATE).result(binding)
      Object.class_eval code, SKETCH_PATH, -1
    end
  end

  # Read in the sketch source code. Needs to work both online and offline.
  def self.read_sketch_source
    File.read(SKETCH_PATH)
  end
end

Processing.load_and_run_sketch 


