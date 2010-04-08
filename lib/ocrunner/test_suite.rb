module OCRunner
  class TestSuite
    
    # Container for test suite info
    
    attr :name
    attr_accessor :cases, :time
    
    def initialize(name)
      @name = name
      @cases = []
    end
  end
end