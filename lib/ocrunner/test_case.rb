module OCRunner
  class TestCase
    attr :name
    attr_accessor :passed
    attr_accessor :path
    attr_accessor :line
    attr_accessor :message
    
    def initialize(name)
      @name = name
    end
  end
end