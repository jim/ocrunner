require 'trollop'

module OCRunner
  module CLI
    def run
      opts = Trollop::options do
        version "0.1 (c) 2010 Jim Benton"
        banner <<-EOS
      ocrunner is a small ruby wrapper for running automated XCode builds.

      Usage:
             ocrunner [options]
      where [options] are:
      EOS
        opt :sdk, "SDK to build against", :default => 'iphonesimulator3.1.3'
        opt :target, 'Target to build', :default => 'Test'
        opt :config, "Configuration to use", :default => 'Debug'
        opt :parallel, "Use multiple processors to build (parallelizeTargets)", :type => :boolean, :default => true
        opt :debug_command, "Print xcodebuild command and exit", :type => :boolean, :default => false
        opt :verbose, "Display all xcodebuild output after summary", :type => :boolean, :default => false
      end
      
      OCRunner::TestRunner.new(opts)
      
    end
  end
end