# encoding: utf-8

require File.expand_path("../../helpers", __FILE__)

module RubyVPS
  module CLI
    class Server < Thor
      include Thor::Actions
      include Thor::Base
      include RubyVPS::Helpers

      method_option :ip,       :type => :string, :aliases => "-i", :required => true, :desc => "The IP of the server you want to prepare."
      method_option :port,     :type => :string, :aliases => "-p", :default => "22", :desc => "The port you want to connect through."
      method_option :password, :type => :string, :aliases => "-P", :desc => "Provide the root users' password for your server."

      method_option :set_ssh_port,          :type => :string, :required => true, :default => "22", :desc => "Change SSH Port for security reasons."
      method_option :set_deployer_password, :type => :string, :required => true, :desc => "The password for the deployment user."
      method_option :set_ruby_version,      :type => :string, :required => true, :default => "1.9.2", :desc => "Will be installed with RVM (Ruby Version Manager)."

      desc "init", "Does the initial server provisioning and setup."

      def init
        say "Attempting to connect to server #{options[:ip]} on port #{options[:port]}.."

        master_conf = File.read(File.expand_path("../scripts/server/master.conf.erb", __FILE__))

        Net::SSH.start(options[:ip], 'root', :password => options[:password], :port => options[:port]) do |ssh|
          say "Connection established! Preparing to perform initial server provisioning..", :green

          ssh.exec!(provision_script("server", binding)) do |channel, stream, data|
            puts data if stream == :stdout
            channel.send_data("#{options[:set_deployer_password]}\n") if data =~ /Password\:/
          end

          say ""
          say "The server has been provisioned, a short summary:", :green
          say "-------------------------------------------------"
          say "* Updated package list, upgraded all installed packages to the latest version"
          say "* Installed a bunch of common useful utilities/packages like the following, and more:"
          say "  gcc build-essential htop curl git openssl ufw tree rsync imagemagick nano vim"
          say "* Installed Ruby Version Manager (RVM)"
          say "* Ruby installed: #{options[:set_ruby_version]} (set as default)"
          say "* Gems installed: bundler, foreman"
          say "* Created the \"deployer\" user with sudo privileges"
          say "* Set the default RACK_ENV and RAILS_ENV to production"
          say "* Changed SSH port from #{options[:port]} to #{options[:set_ssh_port]}" if options[:set_ssh_port] != options[:port]
          say "* Enabled firewall (UFW), only allowing external access from ports: 80, 433 and #{options[:set_ssh_port]} (security)"
          say "* Disable password-based ssh logins as root (security)"
          say ""
          say "From now on, log in with: $ ssh deployer@#{options[:ip]} -p #{options[:set_ssh_port]} # password: #{options[:set_deployer_password]}"
          say ""
          say "If you need to perform tasks as root, use sudo:"
          say ""
          say "  $ sudo         # perform single task as deloyer, no password required"
          say "  $ sudo su root # log in as root from deployer, no password required"
          say ""
          say "If you need more ports enabled, use the \"ufw\" utility:"
          say ""
          say "  $ sudo ufw allow <port> # for if you use Thin, Mongrel on ports. Not required if you use Unicorn over a Unix socket, or Passenger"
        end

        FileUtils.mkdir_p("./config")
        File.open("./config/deploy.yml", "w") do |file|
          file.write({
            :ip       => options[:ip],
            :port     => options[:set_ssh_port],
            :password => options[:set_deployer_password]
          }.to_yaml)
        end

        say ""
        say "Created configuration file in ./config/deploy.yml containing connection options.", :green
        say "This is required to perform any other actions with RubyVPS on your server."
        say "It contains the ip and port of the server, and the password of the \"deployer\" user."

        File.open("./.gitignore", "a") do |gitignore|
          gitignore.write "\nconfig/deploy.yml"
        end

        say ""
        say "config/deploy.yml added to .gitignore", :green
        say "You don't want to store such credentials in your git repository."

      rescue Net::SSH::AuthenticationFailed => e
        say "\nCould not connect to server (could not authenticate). Please ensure the root password is correct.", :red
        puts "\n#{e.backtrace}"
      end

      method_option :key, :type => :string, :aliases => "-k", :default => File.join(ENV['HOME'], '.ssh', 'id_rsa.pub')

      desc "install-ssh-key", "Installs your local ssh key on the remote server."

      def install_ssh_key
        unless File.exist?(options[:key])
          say "#{key} - is not a file.", :red
          exit
        end

        execute_remotely!(
          %{mkdir -p ~/.ssh && echo "#{File.read(options[:key])}" >> ~/.ssh/authorized_keys},
          "Preparing to install ssh key.."
        )
      end

      desc "generate-remote-ssh-key", "Generates a id_rsa/id_rsa.pub key pair on the remote server."

      def generate_remote_ssh_key
        execute_remotely!(
          "rm ~/.ssh/id_rsa ~/.ssh/id_rsa.pub > /dev/null 2>&1; ssh-keygen -N '' -t rsa -f ~/.ssh/id_rsa",
          "Preparing to generate a new ssh key.."
        )
      end

      desc "remote-ssh-key", "Displays the public ssh key (id_rsa.pub) of the remote server."

      def remote_ssh_key
        execute_remotely!(
          %{cat ~/.ssh/id_rsa.pub || echo "Remote key not yet generated!"},
          "Preparing to read the public ssh key.."
        )
      end

      method_option :command, :aliases => "-c", :type => :string, :required => true

      desc "remote-command", "Run a command on the remote server."

      def remote_command
        execute_remotely!(options[:command], "Running remote command..")
      end

    end
  end
end
