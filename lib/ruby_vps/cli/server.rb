# encoding: utf-8

require 'net/ssh'

module RubyVPS
  module CLI
    class Server < Thor
      include Thor::Actions
      include Thor::Base

      method_option :ip,            :type => :string, :aliases => "-i", :required => true, :desc => "The IP of the server you want to prepare."
      method_option :port,          :type => :string, :aliases => "-p", :default => "22", :desc => "The port you want to connect through."
      method_option :root_password, :type => :string, :desc => "Provide the root users' password for your server."

      method_option :set_ssh_port,          :type => :string, :required => true, :default => "22", :desc => "Change SSH Port for security reasons."
      method_option :set_deployer_password, :type => :string, :required => true, :desc => "The password for the deployment user."
      method_option :ruby_version,          :type => :string, :required => true, :default => "1.9.2", :desc => "Will be installed with RVM (Ruby Version Manager)."

      desc "init", "Sets up a deployment user, RVM (Ruby Version Manager) and provisions the Linux server with basic packages."

      def init
        command = <<-EOS
          apt-get update -y
          apt-get install -y aptitude

          aptitude update -y
          aptitude safe-upgrade -y

          aptitude install -y \
          gcc g++ build-essential bison openssl libreadline6 libreadline6-dev \
          htop git-core curl wget ufw tree rsync psmisc nano vim gdb imagemagick \
          zlib1g zlib1g-dev libssl-dev libyaml-dev libxml2-dev libxslt-dev \
          autoconf libpcre3 libpcre3-dev libpcrecpp0 libc6-dev ncurses-dev

          useradd deployer -s /bin/bash -m --password="$(openssl passwd #{options[:deployer_password]})"

          if [[ $(cat /etc/sudoers) != *deployer* ]]; then
            sed -i "/root.*ALL=(ALL) ALL/ a\\deployer ALL\=\(ALL\) NOPASSWD\: ALL" /etc/sudoers
          fi

          curl https://raw.github.com/meskyanichi/provisioner/master/lib/rvm/gemrc > /home/deployer/.gemrc
          chown deployer:deployer /home/deployer/.gemrc

          mkdir -p /var/applications
          chown -R deployer:www-data /var/applications

          aptitude install -y libsqlite3-0 libsqlite3-dev sqlite3 openjdk-6-jre-headless

          bash < <(curl -s https://rvm.beginrescueend.com/install/rvm)

          if [[ $(cat ~/.bashrc) != */usr/local/rvm/scripts/rvm* ]]; then
            echo -e "\n[[ -s /usr/local/rvm/scripts/rvm ]] && source /usr/local/rvm/scripts/rvm\n\n" | cat - ~/.bashrc > ~/.bashrc.tmp
            mv ~/.bashrc.tmp ~/.bashrc && source ~/.bashrc
          fi

          curl https://raw.github.com/meskyanichi/provisioner/master/lib/rvm/gemrc > ~/.gemrc

          rvm install #{options[:ruby_version]}
          rvm use #{options[:ruby_version]} --default

          gem install bundler foreman backup
          gem install bundler --pre

          usermod -G rvm deployer

          echo -e "export RACK_ENV=production\nexport RAILS_ENV=production\n" | cat - /home/deployer/.bashrc > /home/deployer/.bashrc.tmp
          mv /home/deployer/.bashrc.tmp /home/deployer/.bashrc

          sed -i "s/Port 22/Port #{options[:set_ssh_port]}/" /etc/ssh/sshd_config
          /etc/init.d/ssh reload

          ufw allow #{options[:set_ssh_port]}
          ufw allow 80
          ufw allow 443
          ufw --force enable

          passwd -l root
        EOS

        say "Attempting to connect to server (#{options[:ip]}).."

        Net::SSH.start(options[:ip], 'root', :password => options[:root_password], :port => options[:port]) do |ssh|
          say "Connection established! Preparing to provision server..", :green

          ssh.exec!(command) do |channel, stream, data|
            puts data if stream == :stdout
            channel.send_data("#{options[:set_deployer_password]}\n") if data =~ /Password\:/
          end

          say ""
          say "The server has been provisioned, a short summary:", :green
          say "-------------------------------------------------", :green
          say "* Basic packages"
          say "* Ruby Version Manager (RVM) and install #{options[:ruby_version]}"
          say "* Create the \"deployer\" user (and grant sudo-privileges), add to RVM group, etc."
          say "* Install gems: bundler, upstart"
          say "* Set the default RACK_ENV and RAILS_ENV to production"
          say "* Changing SSH port from #{options[:port]} to #{options[:set_ssh_port]}"
          say "* Enable firewall with UFW, allowing only ports 80, 433 and #{options[:set_ssh_port]} for security"
          say "* Disable password-based ssh logins as root for security"

        end
      rescue Net::SSH::AuthenticationFailed => e
        say "\nCould not connect to server (could not authenticate). Please ensure the root password is correct.", :red
        puts "\n#{e.backtrace}"
      end

      method_option :key,  :type => :string, :aliases => "-k", :default => File.join(ENV['HOME'], '.ssh', 'id_rsa.pub')
      method_option :ip,   :type => :string, :aliases => "-i", :required => true
      method_option :user, :type => :string, :aliases => "-u", :required => true, :default => "deployer"
      method_option :port, :type => :string, :aliases => "-p", :default => "22"

      desc "install-ssh-key", "Installs your local ssh key on the remote server."

      def install_ssh_key
        unless File.exist?(options[:key])
          say "#{key} - is not a file.", :red
          exit
        end

        say "Going to install '#{options[:key]}' for '#{options[:user]}' at '#{options[:ip]}'..", :green
        command = %Q{cat '#{options[:key]}' | ssh #{options[:user]}@#{options[:ip]} -p #{options[:port]} "mkdir -p .ssh && cat - >> .ssh/authorized_keys"}

        if %x[ #{command} ].empty?
          say "SSH key for '#{options[:user]}' was successfully installed to '#{options[:ip]}'.", :green
        else
          say "Could not install your SSH key.", :red
        end
      end

      method_option :ip,       :type => :string, :aliases => "-i", :required => true
      method_option :user,     :type => :string, :aliases => "-u", :required => true, :default => "deployer"
      method_option :port,     :type => :string, :aliases => "-p", :default => "22"

      desc "generate-remote-ssh-key", "Generates a id_rsa/id_rsa.pub key pair on the remote server."

      def generate_remote_ssh_key
        connection = %Q{ ssh #{options[:user]}@#{options[:ip]} -p #{options[:port]} }
        response   = %x[ #{connection} "rm ~/.ssh/id_rsa ~/.ssh/id_rsa.pub > /dev/null 2>&1; ssh-keygen -N '' -t rsa -f ~/.ssh/id_rsa"]

        if response =~ /Generating public\/private rsa key pair/
          say "The SSH public/private keys have been generated in ~/.ssh/id_rsa and ~/.ssh/id_rsa.pub", :green
        else
          say "Could not generate new public/private keys.", :red
        end
      end

      method_option :ip,       :type => :string, :aliases => "-i", :required => true
      method_option :user,     :type => :string, :aliases => "-u", :required => true, :default => "deployer"
      method_option :port,     :type => :string, :aliases => "-p", :default => "22"

      desc "remote-ssh-key", "Displays the public ssh key (id_rsa.pub) of the remote server."

      def remote_ssh_key
        connection = %Q{ ssh #{options[:user]}@#{options[:ip]} -p #{options[:port]} }
        response   = %x[ #{connection} "cat ~/.ssh/id_rsa.pub" ]

        if response.empty?
          say "Could not find the id_rsa.pub public ssh key.", :red
        else
          say  "Public ssh key found!", :green
          puts "\n#{response}"
        end
      end

    end
  end
end
