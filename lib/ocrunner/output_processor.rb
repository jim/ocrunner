module OCRunner
  class OutputProcessor < ParseMachine

    include Console
  
    def initialize(out, options)
      initialize_state
      @passed = true
      @suites = []
      @log = ''
      @out = out
      @options = options
      @compilation_error_occurred = false
    end
  
    def process_line(line)
      @log << line unless line =~ /setenv/
      process_console_output(line)
      @out.flush
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

    def display_results
      @suites.each do |suite|
        suite.failed_cases.each do |kase|
          out indent red("[#{suite.name} #{kase.name}] FAILED")
          kase.errors.each do |error|
            out indent 2, "on line #{error.line} of #{clean_path(error.path)}:"
            error.message.each_line do |line|
              out indent 2, red(line.strip)
            end
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
      
      puts @log if @options[:verbose] || (@compilation_error_occurred && @options[:loud_compilation])
      puts red "A compilation error occurred" if @compilation_error_occurred
      puts @output.join("\n")
      puts
    end

    def process_console_output(line)
      process_input(line)
    end
    
    default_state :ready
    
    state :ready, {
      :start_suite => :suite_running,
      :fail_build => :build_failed,
      :fail_without_project => :build_failed
    }
    
    state :suite_running, {
      :start_case => :case_running,
      :end_suite => :ready
    }
    
    state :case_running, {
      :fail_case => :suite_running,
      :pass_case => :suite_running,
      :start_error => :recording_error,
      :start_log => :recording_log,
      :log_line => :case_running
    }
    
    state :recording_error, {
      :fail_case => :suite_running,
      :record_error => :recording_error,
      :start_error => :recording_error
    }
    
    state :recording_log, {
      :record_log => :recording_log,
      :end_log => :case_running
    }
    
    state :build_failed, {
      :record_build_log => :build_failed
    }

    match "[\\-|\\+](\\[.+\\]):(\\d+):(.+):\033\\[0m"
    event :log_line do |line, signature, line_number, file|
      out
      out indent blue("#{signature} logged on line #{line_number} of #{clean_path(file)}:")
      out indent 2, line.slice(line.index("\033\[35m")..-1)
    end
        
    match '[\-|\+](\[.+\]):(\d+):(.+):'
    event :start_log do |line, signature, line_number, file|
      out
      out indent blue("#{signature} logged on line #{line_number} of #{clean_path(file)}:")
      out indent 2, line.slice(line.index("\033\[35m")..-1)
    end
    
    match "\033\\[0m"
    event :end_log do |line|
      out indent 2, line
      out
    end

    match /.+/
    event :record_log do |line|
      out indent 2, line
    end
    
    match /Test Case '-\[.+ (.+)\]' started/
    event :start_case do |line, case_name|
      @current_case = TestCase.new(case_name)
      @current_suite.cases << @current_case
    end
    
    match /Test Case .+ passed/
    event :pass_case do
      @current_case = nil
      print(green('.'))      
    end
    
    match /Test Case .+ failed/
    event :fail_case do 
      print(red('.'))
      @current_case.fail!
      @passed = false
      @current_case = nil
    end
    
    match /(.+\.m):(\d+): error: -\[(.+) (.+)\] :(?: (.+):?)?/
    event :start_error do |line, file, line_number, klass, method, message|
      @current_case.errors << TestError.new(file, line_number, message)
    end

    match /(.+)/
    event :record_error do |line, message|
      @current_case.errors.last.message << message + "\n"
    end

    match /Test Suite '([^\/]+)' started/
    event :start_suite do |line, suite_name|
      @current_suite = TestSuite.new(suite_name)
      @suites << @current_suite
      print "#{suite_name} "
    end
    
    match /^Executed.+\(([\d\.]+)\) seconds/
    event :end_suite do |line, seconds|
      @current_suite.time = seconds
      print "\n" # clear console line      
    end
    
    match /The executable for the test bundle at (.+\.octest) could not be found/
    event :executable_not_found do |line, test_path|
      build_error("Test executable #{clean_path(text_path)} could not be found")
    end

    match /.+\.m:\d+: error: .*/
    match /".+", referenced from:/
    match /-\[\w+ \w+\] in .+\.o/
    match /Bus error/
    match /Segmentation fault/
    event :fail_build do |line|
      compilation_error_occurred!
      build_error(line)
    end

    match /does not contain an Xcode project/
    event :fail_without_project do |line|
      build_error('No Xcode project was found.')
    end

    match /.+/
    event :record_build_log do |line|
      @log << line
    end
 
    def compilation_error_occurred!
      @compilation_error_occurred = true
    end
  
  end
end