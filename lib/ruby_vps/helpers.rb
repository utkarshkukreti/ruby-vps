# encoding: utf-8

require 'yaml'

module RubyVPS
  module Helpers

    def self.included(base)
      base.send(:include, InstanceMethods)
    end

    module InstanceMethods
      def load_connection_options!
        if File.exist?(config = "./config/deploy.yml")
          say "Connection options loaded from #{config}!", :green
          YAML.load_file(config)
        else
          say "Could not load connection options from ./config/deploy.yml", :red
          exit 1
        end
      end

      def execute_remotely!(command, message)
        options = load_connection_options!

        say "Attempting to connect to server.."

        Net::SSH.start(options[:ip], 'deployer', :password => options[:password], :port => options[:port]) do |ssh|
          say "Connection established! #{message}", :green
          ssh.exec!(command) do |channel, stream, data|
            puts data if stream == :stdout
          end
          say "Done!", :green
        end
      rescue Net::SSH::AuthenticationFailed => e
        say "\nCould not connect to the server (could not authenticate). Please ensure the password is correct.", :red
        puts "\n#{e.backtrace}"
      end
    end

  end
end
