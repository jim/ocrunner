module OCRunner
  class ParseMachine
    
    if RUBY_VERSION < '1.9'
      require 'oniguruma'
      include Oniguruma
    end
    
    class << self
      attr_accessor :events, :states
      def match(regex)
        @next_event ||= {}
        @next_event[:regexes] ||= []
        @next_event[:regexes] << regex
      end
      def event(name, options={}, &block)
        @events ||= []
        @events << @next_event.merge(
          :name => name,
          :options => options,
          :callback => block
        )
        @next_event = nil
      end
      def state(name, transitions={})
        @states ||= {}
        @states[name] ||= {}
        @states[name][:transitions] = transitions
      end
      def default_state(default_state)
        @states ||= {}
        @states[default_state] ||= {}
        @states[default_state][:default] = true
      end
    end
    
    def initialize_state
      @state = default_state
      raise "Default state not defined" if @state.nil?
    end
    
    def default_state
      self.class.states.each_pair do |state_name, state_definition|
        return state_name if state_definition[:default] == true
      end
    end    
    
    def event(name)
      self.class.events.find do |event|
        event[:name] == name
      end
    end
   
   def process_input(line)
     self.class.events.each do |event|
       if self.class.states[@state][:transitions].has_key?(event[:name])
         event[:regexes].each do |regex|
           if regex.is_a?(String)
             if RUBY_VERSION < '1.9'
               regex = ORegexp.new(regex) 
             else
               regex = Regexp.new(regex) 
             end
           end
           if (match = regex.match(line))
             args = [line] + match[1..-1]
             self.instance_exec(*args, &event[:callback]) if event[:callback]
             @state = self.class.states[@state][:transitions][event[:name]]
             return
           end
         end
       end
     end
   end
    
  end
end
