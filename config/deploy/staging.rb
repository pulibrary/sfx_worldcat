set :branch, ENV['BRANCH'] || 'master'

server 'lib-jobs-staging1', user: 'deploy', roles: %w{app}