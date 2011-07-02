# encoding: utf-8

module RubyVPS
  module Helpers

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)
    end

    module ClassMethods
      def connection_options
        method_option :ip,       :type => :string, :aliases => "-i", :required => true
        method_option :user,     :type => :string, :aliases => "-u", :default => "deployer"
        method_option :password, :type => :string, :aliases => "-P"
        method_option :port,     :type => :string, :aliases => "-p", :default => "22"      
      end
    end

    module InstanceMethods
      def execute_remotely!(command, message, options)
        say "Attempting to connect to server.."

        Net::SSH.start(options[:ip], options[:user], :password => options[:password], :port => options[:port]) do |ssh|
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