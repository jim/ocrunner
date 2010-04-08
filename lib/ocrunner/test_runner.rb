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
      
      setup
      build_command
      run_tests
      summarize
      display_results
    end
  
    def setup
      puts "="*80
      puts
    end
  
    def build_command
      @command = "xcodebuild -target #{@options[:target]} -configuration #{@options[:config]} " +
                 "-sdk #{@options[:sdk]} #{@options[:parallel] ? '-parallelizeTargets' : ''} build"
     if @options[:debug_command]
       puts @command
       exit
     end
    end
  
    def run_tests
      IO.popen("#{@command} 2>&1") do |f| 
        while line = f.gets do 
          @log << line
          process_console_output(line)
          $stdout.flush
        end
      end
    end
  
    def summarize
      
      @suites.each do |suite|
        suite.cases.reject {|kase| kase.passed}.each do |kase|
          out
          out '  ' + red("[#{suite.name} #{kase.name}] FAIL")
          kase.errors.each do |error|
            out '    ' + red(error.message) + " line #{error.line} of #{clean_path(error.path)}"
          end
        end
        out
      end
      
      @suites.each do |suite|
        failed = suite.cases.reject {|c| c.passed}
        out "Suite '#{suite.name}': #{suite.cases.size - failed.size} passes and #{failed.size} failures in #{suite.time} seconds."
      end
      
      out
      
      if @passed
        build_succeeded
      else
        build_failed
      end
    end
    
    def display_results
      puts @log if @options[:verbose] || compilation_error_occurred
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

      # test case started
      if line =~ /Test Case '-\[.+ (.+)\]' started/
        @current_case = TestCase.new($1)
        @current_suite.cases << @current_case
      end
    
      # test case passed
      if line =~ /Test Case .+ passed/
        @current_case.passed = true
        @current_case = nil
        print(green('.'))
      end
      
      # test failure
      if line =~ /(.+\.m):(\d+): error: -\[(.+) (.+)\] :(?: (.+):?)? /
        @current_case.passed = false
        @current_case.errors << TestError.new($1, $2, $5)
        @passed = false
        print red('.')
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
      
      # compilation reference error
      if line =~ /"(.+)", referenced from:/
        compilation_error_occurred!
        build_error($&)
      end
      if line =~ /-\[\w+ \w+\] in .+\.o/
        compilation_error_occurred!
        build_error($&)
      end
      
      # no Xcode project found
      if line =~ /does not contain an Xcode project/
        build_error('No Xcode project was found.')
      end
      
    end
   
    def compilation_error_occurred!
      @compilation_error_occurred = true
    end
   
    def out(line = '')
      @output << line
    end
    
    def clean_path(path)
      path.gsub(@current_directory + '/', '')
    end
  
    def growl(message)
      if @options[:growl]
        `growlnotify -i "xcodeproj" -m "#{message}" `
      end
    end
  
  end
end