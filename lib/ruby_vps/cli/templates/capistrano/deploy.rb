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

set :db_migrate,      true

default_run_options[:pty] = <%= options[:default_run_options] ? "true" : "false" %>

role :web, "<%= options[:ip] %>"
role :app, "<%= options[:ip] %>"
role :db,  "<%= options[:ip] %>", :primary => true
