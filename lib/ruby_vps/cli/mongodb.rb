# encoding: utf-8

require File.expand_path("../../helpers", __FILE__)

module RubyVPS
  module CLI
    class MongoDB < Thor
      include Thor::Actions
      include RubyVPS::Helpers

      method_option :version, :type => :string, :aliases => "-v", :default => "1.8.2"
      method_option :bit,     :type => :string, :aliases => "-b", :default => "64"

      desc "provision", "Provisions the Linux server with MongoDB."

      def provision
        version = options[:version]
        bit = case options[:bit]
        when "32" then "i686"
        when "64" then "x86_64"
        else raise "Choose either 32 or 64 bit"
        end

        execute_remotely! provision_script("mongodb", binding), "Preparing to install MongoDB.."
      end

    end
  end
end
