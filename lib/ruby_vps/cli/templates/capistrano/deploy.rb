# encoding: utf-8

$:.unshift(File.expand_path('./lib', ENV['rvm_path']))
require 'rvm/capistrano'
require 'ruby_vps/capistrano'

set :application, "<%= options[:application] %>"
set :repository,  "<%= options[:repository] %>"
set :branch,      "<%= options[:branch] %>"

set :rvm_ruby_string, "<%= options[:ruby_version] %>"
set :deploy_to,       "<%= File.join(options[:deploy_to], options[:application]) %>"
set :user,            "<%= options[:user] %>"
set :scm,             :<%= options[:scm] %>
set :port,            <%= options[:port] %>
set :use_sudo,        <%= options[:use_sudo] ? "true" : "false" %>

default_run_options[:pty] = <%= options[:default_run_options] ? "true" : "false" %>

role :web, "<%= options[:ip] %>"
role :app, "<%= options[:ip] %>"
role :db,  "<%= options[:ip] %>", :primary => true

# Note:
# after deploy:restart, the processes in ./Procfile will be
# (re)exported and (re)started on the server by ruby_vps/capistrano
#
# Any command you want to run before the processes are (re)exported and (re)started
# must be defined inside "task :restart do; end" or a previously invoked task.
namespace :deploy do
  task :restart do
    # Example for pre-compiling assets in >= Rails 3.1
    # run "cd #{release_path} && RAILS_ENV=production bundle exec rake assets:precompile"
  end
end

# Tasks:
# Run `cap -T` to see a list of available Capistrano tasks provided by RubyVPS
# commands include start/stop/restarting of processes.

# Concurrency:
# If you want to deploy or re-export with different concurrency levels for your processes
# you can pass in the concurrency level using the C environment variable, for example:
#
#   $ C="web=2 worker=3 pubsub=1" cap deploy
#   $ C="web=1 worker=2 pubsub=1" cap foreman:export foreman:restart
