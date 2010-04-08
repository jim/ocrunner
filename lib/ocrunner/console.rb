# color helpers courtesy of RSpec http://github.com/dchelimsky/rspec

module OCRunner
  module Console
    def colorize(text, color_code)
      "#{color_code}#{text}\033[0m"
    end

    def red(text); colorize(text, "\033[31m"); end
    def green(text); colorize(text, "\033[32m"); end
  end
end