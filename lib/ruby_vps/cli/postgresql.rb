# encoding: utf-8

require 'net/ssh'
require File.expand_path("../../helpers", __FILE__)

module RubyVPS
  module CLI
    class PostgreSQL < Thor
      include Thor::Actions
      include RubyVPS::Helpers

      method_option :version, :type => :string, :aliases => "-v", :default => "9.0.4"
      connection_options

      desc "provision", "Provisions the Linux server with PostgreSQL."

      def provision
        version = options[:version]

        command = <<-EOS
          mkdir ~/tmp
          cd ~/tmp

          sudo useradd postgres -s /bin/bash -m

          wget http://ftp9.us.postgresql.org/pub/mirrors/postgresql/source/v#{version}/postgresql-#{version}.tar.gz
          tar xvfz postgresql-#{version}.tar.gz
          cd postgresql-#{version}
          sudo ./configure \
          --prefix=/etc/postgresql \
          --with-openssl \
          --with-perl

          sudo make
          sudo make install

          sudo mkdir -p /usr/local/pgsql/data
          sudo chown -R postgres /usr/local/pgsql
          sudo su - postgres -c "/etc/postgresql/bin/initdb -D /usr/local/pgsql/data --encoding=UTF8 --locale=en_US.UTF8"

          echo "
          start on runlevel [2345]
          stop on runlevel [016]
          respawn

          exec su -c '/etc/postgresql/bin/postgres -D /usr/local/pgsql/data' postgres
          " | sudo tee /etc/init/postgresql.conf

          sleep 1 && sudo restart postgresql || sudo start postgresql
          sleep 5 && sudo su - postgres -c "/etc/postgresql/bin/createuser deployer --createdb --no-createrole --no-superuser"
        EOS

        execute_remotely!(command, "Preparing to install PostgreSQL..", options)
      end

    end
  end
end
