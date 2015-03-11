require 'ostruct'
require 'fileutils'
require 'rbconfig'
require_relative '../jruby_art/config'
require_relative '../jruby_art/version'


module Processing
  
  # Utility class to handle the different commands that the 'rp5' command
  # offers. Able to run, watch, live, create, app, and unpack
  class Runner
    HELP_MESSAGE = <<-EOS
    JRubyArt Version: #{JRubyArt::VERSION}
    
    JRubyArt is a little shim between Processing and JRuby that helps
    you create sketches of code art.
    
    Usage:
    k9 create some_new_sketch 640 480
    jruby some_new_sketch.rb
    
    k9 run sketch.rb
   
    EOS
    
    WIN_PATTERNS = [
                      /bccwin/i,
                      /cygwin/i,
                      /djgpp/i,
                      /mingw/i,
                      /mswin/i,
                      /wince/i
    ]
    
    attr_reader :os
    
    # Start running a ruby-processing sketch from the passed-in arguments
    def self.execute
      runner = new
      runner.parse_options(ARGV)
      runner.execute!
    end
    
    # Dispatch central.
    def execute!
      case @options.action
      when 'run'    then run(@options.path, @options.args)
      # when 'watch'  then watch(@options.path, @options.args)
      when 'wrap'   then wrap(@options.path, @options.args)
      when 'create' then create(@options.path, @options.args)
      # when 'app'    then app(@options.path)
      when 'setup'  then setup(@options.path)
      when /-v/     then show_version
      when /-h/     then show_help
      else
        show_help
      end
    end
    
    # Parse the command-line options. Keep it simple.
    def parse_options(args)
      @options = OpenStruct.new
      @options.wrap = !args.delete('--wrap').nil?
      @options.action = args[0] || nil
      @options.path = args[1] || File.basename(Dir.pwd + '.rb')
      @options.args = args[2..-1] || []
    end
    
    # Create a fresh Ruby-Processing sketch, with the necessary
    # boilerplate filled out.
    def create(sketch, args)
      require_relative 'creator'
      Processing::ClassSketch.new.create!(sketch, args)
    end
    
    def wrap(sketch, args)
      require_relative 'writer'
      writer = Processing::Writer.new
      writer.read(sketch)
      writer.write
    end
  
    def run(sketch, args)
      command = ['java', '-jar', jruby_complete, parse, sketch, args].flatten
      exec(*command)
    end
    
    def jruby_complete
      rcomplete = File.join(K9_ROOT, '/lib/ruby/jruby-complete.jar')
      return rcomplete if FileTest.exist?(rcomplete)
      warn "#{rcomplete} does not exist\nTry running `k9 setup install`"
    end

    def parse
      File.join(K9_ROOT, 'lib/jruby_art/parse.rb')
    end
    
    def setup(choice)
      usage = 'Usage: k9 setup [install]'
      installed = FileTest.exist?(File.join(K9_ROOT, '/lib/ruby/jruby-complete.jar'))
      proc_root = FileTest.exist?("#{ENV['HOME']}/.jruby_art/config.yml")
      case choice
      when /install/  # download and install jruby-complete and unpack examples to user home
        system "cd #{K9_ROOT}/vendors && rake"
      else
        puts usage
      end
    end
    
    # Show the standard help/usage message.
    def show_help
      puts HELP_MESSAGE
    end
    
    # Display the current version of Ruby-Processing.
    def show_version
      puts "JRubyArt version #{JRubyArt::VERSION}"
    end
  end
end

