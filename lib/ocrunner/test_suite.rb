module OCRunner
  class TestSuite
    attr :name
    attr_accessor :cases, :time
    
    def initialize(name)
      @name = name
      @cases = []
    end
  end
end