# encoding: utf-8

require 'tempfile'
require 'net/ssh'
require 'net/sftp'
require File.expand_path("../../helpers", __FILE__)

module RubyVPS
  module CLI
    class Nginx < Thor
      include Thor::Actions
      include RubyVPS::Helpers

      def self.source_root
        File.dirname(__FILE__) + "/templates/nginx"
      end

      # general
      method_option :out, :type => :string, :default => "/etc/nginx/conf"

      # config
      method_option :pid,                           :type => :string, :default => "/etc/nginx/tmp/pids/nginx.pid"
      method_option :nginx_user,                    :type => :string, :default => "www"
      method_option :nginx_group,                   :type => :string, :default => "data"
      method_option :worker_processes,              :type => :string, :default => "1"
      method_option :worker_connections,            :type => :string, :default => "1024"
      method_option :server_names_hash_bucket_size, :type => :string, :default => "64"
      method_option :client_max_body_size,          :type => :string, :default => "25"
      method_option :applications_path,             :type => :string, :default => "applications"

      desc "generate-config", "Generates the main nginx configuration file"

      def generate_config
        co = load_connection_options!
        nginx_conf = Tempfile.new("nginx.conf")
        FileUtils.rm(nginx_conf.path)
        template("main.conf", nginx_conf.path)

        Net::SFTP.start(co[:ip], 'deployer', :password => co[:password], :port => co[:port]) do |sftp|
          sftp.upload!(
            nginx_conf.path,
            "tmp/nginx.conf"
          )
        end

        Net::SSH.start(co[:ip], 'deployer', :password => co[:password], :port => co[:port]) do |ssh|
          ssh.exec! "sudo mv ~/tmp/nginx.conf #{options[:out]}/nginx.conf"
        end

        execute_remotely!("sudo start nginx || sudo restart nginx", "Restarting NGINX..")
      end

      # general
      method_option :out, :type => :string, :default => "/etc/nginx/conf/applications", :desc => "Path to store the new conf file."

      # application
      method_option :name,    :type => :string, :required => true, :aliases => "-n", :desc => "Name of your application. Use alphanumeric characters and dashes only."
      method_option :domains, :type => :array,  :required => true, :aliases => "-d", :desc => "Domain names (example: domain.com www.domain.com)"

      # app server
      method_option :app_server,  :type => :string, :aliases => "-a", :desc => "Options: unicorn, thin or mongrel"
      method_option :port_range,  :type => :string, :aliases => "-p", :desc => "Port range (example: 3000..3002). (for thin and mongrel)"
      method_option :unix_socket, :type => :string, :aliases => "-s", :desc => "Path to the app servers' socket. (for unicorn)"

      # secure socket layer
      method_option :crt, :type => :string, :aliases => "-c", :desc => "Path to your SSL .crt file."
      method_option :key, :type => :string, :aliases => "-k", :desc => "Path to your SSL .key file."
      method_option :ssl_redirect, :type => :boolean, :default => false, :aliases => "-r", :desc => "Redirect all requests from HTTP to HTTPS."
      method_option :ssl_path, :type => :string, :default => "/etc/ssl", :desc => "Path to where the SSL files will be copied."

      desc "generate-app-config", "Generates an application-specific configuration file"

      def generate_app_config
        co = load_connection_options!
        app_conf = Tempfile.new("nginx.conf")
        FileUtils.rm(app_conf.path)
        template("app.conf", app_conf.path)

        Net::SFTP.start(co[:ip], 'deployer', :password => co[:password], :port => co[:port]) do |sftp|
          [:crt, :key].each do |file|
            if options[file] and File.exist?(options[file])
              sftp.upload!(
                File.expand_path(options[file]),
                File.join("tmp", File.basename(options[file]))
              )
            end
          end

          sftp.upload!(
            app_conf.path,
            File.join("tmp", "#{options[:name]}.conf")
          )
        end

        Net::SSH.start(co[:ip], 'deployer', :password => co[:password], :port => co[:port]) do |ssh|
          ssh.exec "sudo mv #{File.join("~/tmp", "#{options[:name]}.conf")} " +
          "#{File.join(options[:out], "#{options[:name]}.conf")}"
          [:crt, :key].each do |file|
            if options[file] and File.exist?(options[file])
              ssh.exec "sudo mv ~/tmp/#{File.basename(options[file])} #{options[:ssl_path]}/#{File.basename(options[file])}"
            end
          end
        end

        execute_remotely!("sudo start nginx || sudo restart nginx", "Restarting NGINX..")
      end

      method_option :version, :type => :string, :aliases => "-v", :default => "1.0.4"

      desc "provision", "Provisions the Linux server with NGINX."

      def provision
        command = <<-EOS
          sudo aptitude update
          sudo aptitude install -y autotools-dev libpcre3-dev zlib1g-dev libssl-dev

          mkdir ~/tmp
          cd ~/tmp

          wget http://nginx.org/download/nginx-#{options[:version]}.tar.gz
          tar -zxvf nginx-#{options[:version]}.tar.gz
          cd nginx-#{options[:version]}
          sudo ./configure --prefix=/etc/nginx --sbin-path=/usr/sbin --with-http_ssl_module
          sudo make && sudo make install

          sudo mkdir -p /etc/nginx/logs /etc/nginx/tmp/pids /etc/nginx/conf/applications

          echo "
          start on runlevel [2345]
          stop on runlevel [016]
          respawn

          exec /usr/sbin/nginx -c /etc/nginx/conf/nginx.conf  -g 'daemon off;'
          " | sudo tee /etc/init/nginx.conf

          sleep 1 && sudo restart nginx || sudo start nginx
        EOS

        execute_remotely!(command, "Preparing to install Nginx..")
      end

    end
  end
end
