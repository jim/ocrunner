# color helpers originally courtesy of RSpec http://github.com/dchelimsky/rspec

module OCRunner
  module Console
    def colorize(text, color_code)
      "#{color_code}#{text.to_s}\033[0m"
    end

    def red(text); colorize(text, "\033[31m"); end
    def green(text); colorize(text, "\033[32m"); end
    def blue(text); colorize(text, "\033[34m"); end
    
    def indent(text='')
      "  " + text.to_s
    end
    def present(&block)
      puts
      yield
      puts
    end
  end
end