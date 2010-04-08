require 'trollop'

module OCRunner
  module CLI
    def self.run
      opts = Trollop::options do
        v = File.read(File.join(File.dirname(__FILE__), '../../VERSION')).strip
        version "#{v} (c) 2010 Jim Benton github.com/jim/ocrunner"
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