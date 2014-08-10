require 'net/ssh/proxy/command'

# config valid only for Capistrano 3.1
lock '3.2.1'

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :pty is false
# set :pty, true

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

set :scm, :git
set :log_level, :debug

set :linked_files, %w{config/database.yml .env}
set :linked_dirs, %w{bin log tmp}

set :resque_log_file, "log/resque.log"

set :workers, { high: 1, medium: 1, low: 1 }

namespace :deploy do
  task :restart do
    on roles(:app) do
      execute "touch #{current_path}/tmp/restart.txt"
    end
  end
end

after "deploy:publishing", "deploy:restart"
after "deploy:restart", "resque:restart"
