module OCRunner
  class TestRunner
    include Console
    
    class BuildFailure < StandardError; end

    attr_reader :compilation_error_occurred
    
    def initialize(options)
      @suites = []
      @log = ''
      @current_directory = Dir.pwd
      @options = options
      @passed = true
      @compilation_error_occurred = false
      @output = []
      
      build_command
      setup
      run_tests
      summarize
      display_results
    end
  
    def setup
      puts "-"*80
      puts
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
  
    def run_tests
      
      puts "ocrunner started. control-c to exit, control-\\ to toggle verbosity\n\n"
      
      execute @command do |line|
        @log << line
        process_console_output(line)
        $stdout.flush
      end
    end
  
    def summarize
      
      @suites.each do |suite|
        suite.failed_cases.each do |kase|
          out '  ' + red("[#{suite.name} #{kase.name}] FAIL")
          kase.errors.each do |error|
            out '    ' + red(error.message) + " line #{error.line} of #{clean_path(error.path)}"
          end
        end
        out if suite.failures?
      end
      
      @suites.each do |suite|
        number = suite.failed_cases.size
        out "Suite '#{suite.name}': #{suite.cases.size - number} passes and #{number} failures in #{suite.time} seconds."
      end
      
      out
      
      if @passed
        build_succeeded
      else
        build_failed
      end
    end
    
    def display_results
      puts @log if @options[:verbose] || (compilation_error_occurred && @options[:loud_compilation])
      puts @output.join("\n")
      puts
    end
    
    def build_error(message)
      out red(message)
      @passed = false
    end

    def build_failed
      growl('BUILD FAILED!')
      out red('*** BUILD FAILED ***')
    end
    
    def build_succeeded
      growl('Build succeeded.')
      out green('*** BUILD SUCCEEDED ***')
    end

    def process_console_output(line)
      
      if @options[:oclog]
        if line.include?("\033\[35m")
          line =~ /[\-|\+](\[.+\]):(\d+):(.+):/
          out blue("#{$1} on line #{$2} of #{clean_path($3)}:")
          out line.slice(line.index("\033\[35m")..-1)
          @debug_output = true unless line.include?("\033[0m")
          return
        end

        if line.include?("\033[0m")
          @debug_output = false
          out line
          out
          return
        end
      
        if @debug_output
          out line
          return
        end 
      end

      # test case started
      if line =~ /Test Case '-\[.+ (.+)\]' started/
        @current_case = TestCase.new($1)
        @current_suite.cases << @current_case
      end
    
      # test case passed
      if line =~ /Test Case .+ passed/
        @current_case = nil
        print(green('.'))
      end
      
      # test failure
      if line =~ /(.+\.m):(\d+): error: -\[(.+) (.+)\] :(?: (.+):?)?/
        @current_case.errors << TestError.new($1, $2, $5)
        test_failure_occurred!
      end

      # start test suite
      if line =~ /Test Suite '([^\/]+)' started/
        @current_suite = TestSuite.new($1)
        @suites << @current_suite
        print "#{$1} "
      end

      # finish test suite
      if @current_suite && line =~ /^Executed/ && line =~ /\(([\d\.]+)\) seconds/
        @current_suite.time = $1
        print "\n" # clear console line
      end

      # test executable not found
      if line =~ /The executable for the test bundle at (.+\.octest) could not be found/
        build_error("Test executable #{clean_path($1)} could not be found")
      end

      # compilation errors
      if !@current_case && line =~ /(.+\.m):(\d+): error: (.*)/
        compilation_error_occurred!
        build_error($&)      
      end
      
      # compilation reference error
      if line =~ /"(.+)", referenced from:/
        compilation_error_occurred!
        build_error($&)
      end
      
      # linking error
      if line =~ /-\[\w+ \w+\] in .+\.o/
        compilation_error_occurred!
        build_error($&)
      end
      
      # bus error
      if line =~ /Bus error/
        build_error('Bus error while running tests.')        
      end      
      
      # segfault
      if line =~ /Segmentation fault/
        build_error('Segmentation fault while running tests.')        
      end
      
      # no Xcode project found
      if line =~ /does not contain an Xcode project/
        build_error('No Xcode project was found.')
      end
      
    end
   
    def compilation_error_occurred!
      @compilation_error_occurred = true
    end
   
    def test_failure_occurred!
      print red('.') if @current_case.passed? # only print a dot for the case's first failure
      @current_case.fail!
      @passed = false
    end
   
    def out(line = '')
      @output << line.rstrip
    end
    
    def clean_path(path)
      return 'unknown' if path.nil?
      path.gsub(@current_directory + '/', '')
    end
  
    def growl(message)
      if @options[:growl]
        execute "growlnotify -i \"xcodeproj\" -m \"#{message}\"" do |error|
          if error =~ /command not found/
            out red('You must have growl and growl notify installed to enable growl support. See http://growl.info.')
          end
        end
      end
    end
  
    def execute(cmd, &block)
      IO.popen("#{cmd} 2>&1") do |f| 
        while line = f.gets do 
          yield line
        end
      end
    end
  
  end
end