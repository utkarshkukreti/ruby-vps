# encoding: utf-8

Capistrano::Configuration.instance(true).load do

  after "deploy:update",  "bundle:install"
  after "deploy:update",  "foreman:export"
  after "deploy:restart", "foreman:restart"

  namespace :bundle do
    desc "Installs the application dependencies"
    task :install, :roles => :app do
      run "cd #{current_path} && bundle --without development test"
    end
  end

  namespace :ruby_vps do
    desc "Run a command on the remote server from the application root ( C='my command' )"
    task :cmd, :roles => :app do
      run "cd #{current_path} && #{ENV['C']}"
    end
  end

  namespace :foreman do
    desc "Export the Procfile to Ubuntu's Upstart configuration"
    task :export, :roles => :app do
      run "cd #{current_path} && rvmsudo foreman export bluepill /etc/bluepill/config " +
          "-f ./Procfile -a #{application} -u #{user} -l #{shared_path}/log " +
          "-t /etc/bluepill/template " + (ENV['C'] ? "-c #{ENV['C']} " : " ") +
          "-p #{ENV['P'] ? ENV['P'] : '5000'}"
    end

    desc "Start the application services"
    task :start, :roles => :app do
      run "rvmsudo bluepill load /etc/bluepill/config/#{application}.pill"
      run "rvmsudo bluepill start"
    end

    desc "Stop the application services"
    task :stop, :roles => :app do
      run "rvmsudo bluepill load /etc/bluepill/config/#{application}.pill"
      run "rvmsudo bluepill stop"
    end

    desc "Restart the application services"
    task :restart, :roles => :app do
      run "rvmsudo bluepill load /etc/bluepill/config/#{application}.pill"
      run "rvmsudo bluepill restart"
    end

    desc "Display logs for a certain process"
    task :logs, :roles => :app do
      run "cd #{current_path}/log && tail -f #{ENV["PROCESS"] || "*"}.log"
    end
  end

  namespace :deploy do
    task :restart do
    end

    task :finalize_update, :except => { :no_release => true } do
      run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)
      run <<-CMD
        rm -rf #{latest_release}/log #{latest_release}/public/system #{latest_release}/tmp/pids &&
        mkdir -p #{latest_release}/public &&
        mkdir -p #{latest_release}/tmp &&
        ln -s #{shared_path}/log #{latest_release}/log &&
        ln -s #{shared_path}/system #{latest_release}/public/system &&
        ln -s #{shared_path}/pids #{latest_release}/tmp/pids
      CMD
    end

  end

end
