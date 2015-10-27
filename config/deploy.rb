set :application, 'mods-profiling-indexer'
set :repo_url, 'https://github.com/sul-dlss/mods-profiling-indexer.git'

ask(:user, 'enter the app username')

ask(:home_parent_dir, %{Enter the full path of the parent of the home dir (e.g. /home)})
set :deploy_to, "#{File.join fetch(:home_parent_dir), fetch(:user), fetch(:application)}"

set :linked_dirs, %w(logs config/collections tmp)
# set :linked_files, %w()

set :stages, %w(dev)

# Default value for :log_level is :debug
set :log_level, :info

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :pty is false
# set :pty, true

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 10
