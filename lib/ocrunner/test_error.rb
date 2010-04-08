module OCRunner
  
  # Container for test failures info
  
  class TestError < Struct.new(:path, :line, :message)
  end
  
end