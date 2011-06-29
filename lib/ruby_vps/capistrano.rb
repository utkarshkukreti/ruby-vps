# encoding: utf-8

Capistrano::Configuration.instance(true).load do

  after 'deploy:update', 'bundle:install'
  after 'deploy:update', 'foreman:export'
  after 'deploy:update', 'foreman:restart'

  namespace :bundle do
    desc "Installs the application dependencies"
    task :install, :roles => :app do
      run "cd #{current_path} && bundle --without development test"
    end
  end

  namespace :foreman do
    desc "Export the Procfile to Ubuntu's upstart scripts"
    task :export, :roles => :app do
      run "cd #{release_path} && rvmsudo bundle exec foreman export upstart /etc/init " +
          "-f ./Procfile -a #{application} -u #{user} -l #{shared_path}/log"
    end

    desc "Start the application services"
    task :start, :roles => :app do
      sudo "start #{application}"
    end

    desc "Stop the application services"
    task :stop, :roles => :app do
      sudo "stop #{application}"
    end

    desc "Restart the application services"
    task :restart, :roles => :app do
      run "sudo start #{application} || sudo restart #{application}"
    end

    desc "Display logs for a certain process"
    task :logs, :roles => :app do
      run "cd #{current_path}/log && cat #{ENV["PROCESS"]}.log"
    end
  end

  namespace :deploy do
    task :restart do
    end
  end

end
