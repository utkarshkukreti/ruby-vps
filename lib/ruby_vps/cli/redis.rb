# encoding: utf-8

require 'net/ssh'

module RubyVPS
  module CLI
    class Redis < Thor
      include Thor::Actions

      method_option :version, :type => :string, :aliases => "-v", :default => "2.2.11"

      method_option :ip,       :type => :string, :aliases => "-i", :required => true
      method_option :user,     :type => :string, :aliases => "-u", :default => "deployer"
      method_option :password, :type => :string, :aliases => "-P"
      method_option :port,     :type => :string, :aliases => "-p", :default => "22"

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

        say "Attempting to connect to server.."

        Net::SSH.start(options[:ip], options[:user], :password => options[:password], :port => options[:port]) do |ssh|
          say "Connected! Installing Redis..", :green

          ssh.exec!(command) do |channel, stream, data|
            puts data if stream == :stdout
          end

          say "Done!", :green
        end
      end

    end
  end
end
