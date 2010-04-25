module OCRunner
  
  # Container for test failure info
  
  class TestError < Struct.new(:path, :line, :message)
  end
  
end