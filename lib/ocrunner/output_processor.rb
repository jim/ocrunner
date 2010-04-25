module OCRunner
  class OutputProcessor < ParseMachine

    include Console
  
    def initialize(out, options)
      initialize_state
      @passed = true
      @suites = []
      @log = ''
      @out = out
      @output = []
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
          out indent red("[#{suite.name} #{kase.name}] FAIL")
          kase.errors.each do |error|
            out indent 2, "on line #{error.line} of #{clean_path(error.path)}:"
            out indent 2, red(error.message) 
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
      puts @output.join("\n")
      puts
    end

    def process_console_output(line)
      self.class.states[@state][:transitions].each_pair do |event_name, new_state|
        event = event(event_name)
        if (match = line.match(event[:regex]))
          self.instance_exec(*match[1..-1], &event[:callback]) if event[:callback]
          # puts red event_name
          # puts blue new_state
          @state = new_state
        end
      end
    
      # if @options[:oclog]
      #   if line.include?("\033\[35m")
      #     line =~ /[\-|\+](\[.+\]):(\d+):(.+):/
      #     out blue("#{$1} on line #{$2} of #{clean_path($3)}:")
      #     out line.slice(line.index("\033\[35m")..-1)
      #     @debug_output = true unless line.include?("\033[0m")
      #     return
      #   end
      # 
      #   if line.include?("\033[0m")
      #     @debug_output = false
      #     out line
      #     out
      #     return
      #   end
      #     
      #   if @debug_output
      #     out line
      #     return
      #   end 
      # end

    end
    
    default_state :ready
    
    state :ready, {
      :start_suite => :suite_running
    }
    
    state :suite_running, {
      :start_case => :case_running,
      :end_suite => :ready
    }
    
    state :case_running, {
      :fail_case => :suite_running,
      :pass_case => :suite_running,
      :case_error => :case_running
    }
    
    match /Test Case '-\[.+ (.+)\]' started/
    event :start_case do |case_name|
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
    event :case_error do |file, line, klass, method, message|
      @current_case.errors << TestError.new(file, line, message)
    end

      # # test failure
      # if line =~ /(.+\.m):(\d+): error: -\[(.+) (.+)\] :(?: (.+):?)?/
      #   @current_case.errors << TestError.new($1, $2, $5)
      # end

    match /Test Suite '([^\/]+)' started/
    event :start_suite do |suite_name|
      @current_suite = TestSuite.new(suite_name)
      @suites << @current_suite
      print "#{suite_name} "
    end
    
    match /^Executed.+\(([\d\.]+)\) seconds/
    event :end_suite do |seconds|
      @current_suite.time = seconds
      print "\n" # clear console line      
    end
    
    match /The executable for the test bundle at (.+\.octest) could not be found/
    event :executable_not_found do |test_path|
      build_error("Test executable #{clean_path(text_path)} could not be found")
    end

      # # compilation errors
      # if !@current_case && line =~ /(.+\.m):(\d+): error: (.*)/
      #   compilation_error_occurred!
      #   build_error($&)
      # end
      #     
      # # compilation reference error
      # if line =~ /"(.+)", referenced from:/
      #   compilation_error_occurred!
      #   build_error($&)
      # end
      #     
      # # linking error
      # if line =~ /-\[\w+ \w+\] in .+\.o/
      #   compilation_error_occurred!
      #   build_error($&)
      # end
      #     
      # # bus error
      # if line =~ /Bus error/
      #   build_error('Bus error while running tests.')
      # end      
      #     
      # # segfault
      # if line =~ /Segmentation fault/
      #   build_error('Segmentation fault while running tests.')
      # end
      #     
      # # no Xcode project found
      # if line =~ /does not contain an Xcode project/
      #   build_error('No Xcode project was found.')
      # end
    
    # end
 
    def compilation_error_occurred!
      @compilation_error_occurred = true
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
  
  end
end