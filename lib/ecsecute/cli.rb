# frozen_string_literal: true

require 'thor'

module Ecsecute
  # Handle the application command line parsing
  # and the dispatch to various command objects
  #
  # @api public
  class CLI < Thor
    # Error raised by this runner
    Error = Class.new(StandardError)

    desc 'version', 'ecsecute version'
    def version
      require_relative 'version'
      puts "v#{Ecsecute::VERSION}"
    end
    map %w(--version -v) => :version

    desc 'exe command', 'Run command on a ecs task'
    method_option :help, aliases: '-h', type: :boolean, desc: 'Display usage information'
    method_option :interactive, aliases: '-i', type: :boolean, desc: 'Run command interactively'
    method_option :cluster , aliases: '-c', type: :string, desc: 'Cluster name'
    method_option :task , aliases: '-t', type: :string, desc: 'Task id'
    method_option :container , aliases: '-C', type: :string, desc: 'Container name'
    def exec(i=true)
      if options[:help]
        invoke :help, ['exec']
      else
        require_relative 'commands/exec'
        Ecsecute::Commands::Exec.new(i, options).execute
      end
    end
  end
end
