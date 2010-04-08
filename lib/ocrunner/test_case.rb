module OCRunner
  class TestCase
    attr :name
    attr_accessor :passed, :path, :line, :message
    
    def initialize(name)
      @name = name
    end
  end
end