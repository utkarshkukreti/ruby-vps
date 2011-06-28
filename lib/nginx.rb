# encoding: utf-8

class Nginx < Thor
  include Thor::Actions

  def self.source_root
    File.dirname(__FILE__) + "/templates/nginx"
  end

  # general
  method_option :out, :type => :string, :default => "/etc/nginx/conf"

  # config
  method_option :pid,                           :type => :string, :default => "/etc/nginx/tmp/pids/nginx.pid"
  method_option :user,                          :type => :string, :default => "www"
  method_option :group,                         :type => :string, :default => "data"
  method_option :worker_processes,              :type => :string, :default => "1"
  method_option :worker_connections,            :type => :string, :default => "1024"
  method_option :server_names_hash_bucket_size, :type => :string, :default => "64"
  method_option :client_max_body_size,          :type => :string, :default => "25"
  method_option :applications_path,             :type => :string, :default => "applications"

  desc "main", "Generates the main nginx configuration file"

  def main
    template("main.conf", File.join(options[:out], "nginx.conf"))
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

  desc "app", "Generates an application-specific configuration file"

  def app
    template("app.conf", File.join(options[:out], "#{options[:name]}.conf"))
    [:crt, :key].each do |file|
      if options[file] and File.exist?(options[file])
        copy_file(File.expand_path(
          options[file]),
          File.join(options[:ssl_path], File.basename(options[file]))
        )
      end
    end
  end
end
