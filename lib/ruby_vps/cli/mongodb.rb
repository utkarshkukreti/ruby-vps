# encoding: utf-8

require 'net/ssh'
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

        command = <<-EOS
          mkdir ~/tmp
          cd ~/tmp

          wget http://fastdl.mongodb.org/linux/mongodb-linux-#{bit}-#{version}.tgz
          tar -xf mongodb-linux-#{bit}-#{version}.tgz
          sudo rm -rf /etc/mongodb
          sudo mv mongodb-linux-#{bit}-#{version} /etc/mongodb

          sudo mkdir -p /data/db /data/log

          echo "
          start on runlevel [2345]
          stop on runlevel [016]
          respawn

          exec /etc/mongodb/bin/mongod --journal --logpath /data/log/mongo.log --dbpath /data/db
          " | sudo tee /etc/init/mongodb.conf

          sleep 1 && sudo restart mongodb || sudo start mongodb
        EOS

        execute_remotely!(command, "Preparing to install MongoDB..")
      end

    end
  end
end
