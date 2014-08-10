require 'net/ssh/proxy/command'

# config valid only for Capistrano 3.1
lock '3.2.1'

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

set :application, "hound"

set :ssh_options, proxy: Net::SSH::Proxy::Command.new('ssh hound@g.devguru.co -W %h:%p')
set :rvm_ruby_version, '2.1.2'
set :bundle_jobs, 8
set :repo_url,  "git@github.com:netguru/hound.git"
set :rails_env, ->{ fetch(:stage) }
set :user, ->{ fetch(:application) }
set :deploy_to, ->{ "/home/#{fetch(:user)}/app" }
set :rvm_type, :system

branches = { production: :production, beta: :beta, staging: :master }
set :branch, ->{ branches[fetch(:stage).to_sym].to_s }

set :remote, "origin"
set :current_revision, ->{ capture("cd #{current_path}; git rev-parse HEAD").strip }
set :scm, :git
set :runner, ->{ "RAILS_ENV=#{fetch(:stage)} bundle exec" }
set :log_level, :info

set :linked_files, %w{config/database.yml .env}
set :linked_dirs, %w{bin log tmp}

after "deploy:publishing", "deploy:restart"
after "deploy:publishing", "resque:restart"
