module OCRunner
  class TestRunner
    include Console
  
    attr :suites
    attr :current_directory
    attr :options
    attr :log
    
    def initialize(options)
      @suites = []
      @log = ''
      @current_directory = Dir.pwd
      @options = options
      run_tests
      display_summary
      puts @log if @options[:verbose]
    end
  
    def clean_path(path)
      path.gsub(@current_directory + '/', '')
    end
  
    def run_tests
      cmd = "xcodebuild -target #{@options[:target]} -configuration #{@options[:config]} " +
            "-sdk #{@options[:sdk]} #{@options[:parallel] ? '-parallelizeTargets' : ''} build"
            
      if @options[:debug_command]
        puts cmd
        exit
      end
            
      IO.popen("#{cmd} 2>&1") do |f| 
        while line = f.gets do 
          @log << line
          process_console_output(line)
          $stdout.flush
        end
      end
    end
  
    def display_summary
      passed = true
      @suites.each do |suite|
        failed = suite.cases.reject {|c| c.passed}
        failed.each do |c|
          passed = false
          puts
          puts '  ' + red("[#{suite.name} #{c.name}] FAIL") + " on line #{c.line} of #{clean_path(c.path)}"
          puts '  ' + c.message unless c.message.nil?
        end
        puts
      end
      
      @suites.each do |suite|
        failed = suite.cases.reject {|c| c.passed}
        puts "Suite '#{suite.name}': #{suite.cases.size - failed.size} passes and #{failed.size} failures in #{suite.time} seconds."
      end
      puts
      if passed
        puts green('*** BUILD SUCCEEDED ***')        
      else
        puts red('*** BUILD FAILED ***')
      end
    end
  
    def process_console_output(line)

      # test case started
      if line =~ /Test Case '-\[\w+ (.+)\]' started/
        @current_case = TestCase.new($1)
      end
    
      # test case passed
      if line =~ /Test Case .+ passed/
        @current_case.passed = true
        @current_suite.cases << @current_case
        @current_case = nil
        print(green('.'))
      end
      
      # test failure
      if line =~ /(.+\.m):(\d+): error: -\[(.+) (.+)\] :(?: (.+):)? /
        @current_case.passed = false
        @current_case.path = $1
        @current_case.line = $2
        @current_case.message = $5
        @current_suite.cases << @current_case
        @current_case = nil
        print red('.')
      end

      # start test suite
      if line =~ /Test Suite '([^\/]+)' started/
        @current_suite = TestSuite.new($1)
        print "#{$1} "
      end

      # finish test suite
      # Executed 4 tests, with 0 failures (0 unexpected) in 0.024 (0.026) seconds
      if @current_suite && line =~ /^Executed/ && line =~ /\(([\d\.]+)\) seconds/
        @current_suite.time = $1
        @suites << @current_suite
        @current_suite = nil
        print "\n" # clear console line
      end
    end
  
  end
end