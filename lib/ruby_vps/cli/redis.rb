# encoding: utf-8

require 'net/ssh'
require File.expand_path("../../helpers", __FILE__)

module RubyVPS
  module CLI
    class Redis < Thor
      include Thor::Actions
      include RubyVPS::Helpers

      method_option :version, :type => :string, :aliases => "-v", :default => "2.2.11"
      connection_options

      desc "provision", "Provisions the Linux server with Redis."

      def provision
        version = options[:version]

        command = <<-EOS
          mkdir ~/tmp
          cd ~/tmp

          wget http://redis.googlecode.com/files/redis-#{version}.tar.gz
          tar -xf redis-#{version}.tar.gz
          sudo rm -rf /etc/redis
          cd redis-#{version}
          sudo make PREFIX=/etc/redis install
          sudo mv redis.conf /etc/redis/redis.conf
          sudo sed -i "s/appendonly no/appendonly yes/" /etc/redis/redis.conf

          echo "
          start on runlevel [2345]
          stop on runlevel [016]
          respawn

          exec /etc/redis/bin/redis-server
          " | sudo tee /etc/init/redis.conf

          sleep 1 && sudo restart redis || sudo start redis
        EOS

        execute_remotely!(command, "Preparing to install Redis..", options)
      end

    end
  end
end
