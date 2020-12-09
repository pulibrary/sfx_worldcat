desc 'Run the incremental process'
task :run_incremental do
  current_date = Time.new.strftime('%Y-%m-%d')
  ruby "tasks/incremental_process.rb > output/#{current_date}-incremental.txt"
  # if returned ok increment the date
  file_name = 'output/incremental/last_incremental_date.txt'
  File.open(file_name, 'w') { |f| f.write(current_date) }
  # TODO: Capture errors and notify the correct people in slack.  Maybe Honey Badger?
end
