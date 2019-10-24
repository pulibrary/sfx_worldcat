# config valid for current version and patch releases of Capistrano
lock "~> 3.11.1"

set :application, "sfx_worldcat"
set :repo_url, "git@github.com:pulibrary/sfx_worldcat.git"

set :deploy_to, '/opt/sfx_worldcat'
set :bundle_flags, '--no-deployment --quiet'

append :linked_dirs, '.bundle'

# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure
