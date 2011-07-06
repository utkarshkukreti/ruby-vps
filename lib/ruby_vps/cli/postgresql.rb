# encoding: utf-8

require File.expand_path("../../helpers", __FILE__)

module RubyVPS
  module CLI
    class PostgreSQL < Thor
      include Thor::Actions
      include RubyVPS::Helpers

      method_option :version, :type => :string, :aliases => "-v", :default => "9.0.4"

      desc "provision", "Provisions the Linux server with PostgreSQL."

      def provision
        execute_remotely! provision_script("postgresql", binding), "Preparing to install PostgreSQL.."
      end

    end
  end
end
