# encoding: utf-8

require File.expand_path("../../helpers", __FILE__)

module RubyVPS
  module CLI
    class Redis < Thor
      include Thor::Actions
      include RubyVPS::Helpers

      method_option :version, :type => :string, :aliases => "-v", :default => "2.2.11"

      desc "provision", "Provisions the Linux server with Redis."

      def provision
        execute_remotely! provision_script("redis", binding), "Preparing to install Redis.."
      end

    end
  end
end
