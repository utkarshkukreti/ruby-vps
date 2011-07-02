# encoding: utf-8

require 'net/ssh'

module RubyVPS
  module CLI
    class MongoDB < Thor
      include Thor::Actions

      method_option :version, :type => :string, :aliases => "-v", :default => "1.8.2"
      method_option :bit,     :type => :string, :aliases => "-b", :default => "64"

      method_option :ip,       :type => :string, :aliases => "-i", :required => true
      method_option :user,     :type => :string, :aliases => "-u", :default => "deployer"
      method_option :password, :type => :string, :aliases => "-P"
      method_option :port,     :type => :string, :aliases => "-p", :default => "22"

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

          sudo mkdir -p /data/db

          echo "
          start on runlevel [2345]
          stop on runlevel [016]
          respawn

          exec /etc/mongodb/bin/mongod --journal --logpath /data/log/mongo.log --dbpath /data/db
          " | sudo tee /etc/init/mongodb.conf

          sleep 1 && sudo restart mongodb || sudo start mongodb
        EOS

        say "Attempting to connect to server.."

        Net::SSH.start(options[:ip], options[:user], :password => options[:password], :port => options[:port]) do |ssh|
          say "Connected! Installing MongoDB..", :green

          ssh.exec!(command) do |channel, stream, data|
            puts data if stream == :stdout
          end

          say "Done!", :green
        end
      end

    end
  end
end
