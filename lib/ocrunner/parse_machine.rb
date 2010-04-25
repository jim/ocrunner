module OCRunner
  class ParseMachine
    class << self
      attr_accessor :events, :states
      def match(regex)
        @next_event ||= {}
        @next_event[:regex] = regex
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
    
  end
end