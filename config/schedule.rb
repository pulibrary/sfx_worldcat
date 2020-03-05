# Example:
#
set :output, '/opt/sfx_worldcat/current/output/cron_log.log'

every '0 2 15 * *' do # Every month on the 15th at 2:00 am
  rake 'run_incremental'
end

# Learn more: http://github.com/javan/whenever
