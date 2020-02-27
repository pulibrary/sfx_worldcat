require 'byebug'

task :run_incremental do
  current_date = Date.new.strftime('%Y-%m-%d')
  ruby "tasks/incremental_process.rb > output/#{current_date}-incremental.txt 2>&1"
  #if returned ok increment the date
end
