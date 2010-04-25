module OCRunner
  class TestRunner
    include Console
    
    class BuildFailure < StandardError; end
    
    def initialize(options)
      @options = options
      @processor = OutputProcessor.new($stdout, @options)
      
      build_command
      setup
      run_tests
    end
  
    def build_command
      @command = "xcodebuild -target #{@options[:target]} -configuration #{@options[:config]} " +
                 "-sdk #{@options[:sdk]} #{@options[:parallel] ? '-parallelizeTargets' : ''} build"
     if @options[:debug_command]
       present do
         puts indent @command
       end
       exit
     end
    end
    
    def setup
      puts "-"*80
      puts
      puts "ocrunner started. control-c to exit, control-\\ to toggle verbosity\n\n"
    end
  
    def run_tests
      execute @command do |line|
        @processor.process_line(line)
      end
      @processor.display_results
    end
  
  end
end