require 'trollop'
require 'fssm'

module OCRunner
  module CLI
    def self.run
      
      Kernel.trap('INT') { puts; exit }
      
      opts = Trollop::options do
        version_number = File.read(File.join(File.dirname(__FILE__), '../../VERSION')).strip
        version "#{version_number} (c) 2010 Jim Benton github.com/jim/ocrunner"
        banner <<-EOS
      ocrunner is a small ruby wrapper for running automated XCode builds.

      Usage:
             ocrunner [options]
      where [options] are:
      EOS
        opt :sdk, "SDK to build against", :default => 'iphonesimulator3.1.3'
        opt :target, 'Target to build', :default => 'Test'
        opt :config, "Configuration to use", :default => 'Debug'
        opt :parallel, "Use multiple processors to build multiple targets (parallelizeTargets)", :type => :boolean, :default => true
        opt :auto, "Watch filesystem for changes and run tests when they occur", :type => :boolean, :default => false
        opt :growl, "Report results using Growl", :type => :boolean, :default => false
        opt :debug_command, "Print xcodebuild command and exit", :type => :boolean, :default => false
        opt :verbose, "Display all xcodebuild output after summary", :type => :boolean, :default => false
        opt :loud_compilation, "Always show verbose output when a compilation or linking error occurs", :type => :boolean, :default => true
      end
      
      execute = Proc.new{ OCRunner::TestRunner.new(opts) }
      execute.call
      
      if opts[:auto]
        FSSM.monitor(Dir.pwd, %w{**/*.m **/*.h}) do
          create { |base, relative| execute.call }
          update { |base, relative| execute.call }
          delete { |base, relative| execute.call }
        end
      end
      
    end
  end
end