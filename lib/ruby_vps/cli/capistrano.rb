# encoding: utf-8

module RubyVPS
  module CLI
    class Capistrano < Thor
      include Thor::Actions

      def self.source_root
        File.dirname(__FILE__) + "/templates/capistrano"
      end

      method_option :ip, :type => :string, :aliases => "-i", :default => "xx.xx.xx.xx"

      method_option :application,  :type => :string, :aliases => "-a", :default => "myapp"
      method_option :repository,   :type => :string, :aliases => "-r", :default => "git@somerepohost.com:myapp.git"
      method_option :branch,       :type => :string, :aliases => "-b", :default => "master"

      method_option :ruby_version, :type => :string, :aliases => "-v", :default => "1.9.2"
      method_option :deploy_to,    :type => :string, :aliases => "-d", :default => "/var/applications/"

      method_option :user,     :type => :string,  :aliases => "-u",  :default => "deployer"
      method_option :scm,      :type => :string,  :aliases => "-s",  :default => "git"
      method_option :port,     :type => :string,  :aliases => "-p",  :default => "22"

      method_option :use_sudo, :type => :boolean, :default => false
      method_option :pty,      :type => :boolean, :default => true

      desc "generate:config", "Generates the main nginx configuration file"

      define_method "generate:config" do
        template("Capfile", "Capfile")
        template("deploy.rb", File.join("config", "deploy.rb"))
      end

    end
  end
end
