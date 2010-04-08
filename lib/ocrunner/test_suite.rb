module OCRunner
  class TestSuite
    
    # Container for test suite info
    
    attr :name
    attr_accessor :cases, :time
    
    def initialize(name)
      @name = name
      @cases = []
    end
    
    def failures?
      @cases.any? {|kase| !kase.passed?}
    end
    
    def failed_cases
      @cases.reject {|kase| kase.passed?}
    end
  end
end