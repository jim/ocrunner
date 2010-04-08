module OCRunner
  class TestSuite
    attr :name
    attr_accessor :cases
    attr_accessor :time
    
    def initialize(name)
      @name = name
      @cases = []
    end
  end
end