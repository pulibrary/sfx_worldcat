require_relative './../lib/sfx_worldcat'

client = Mysql2::Client.new(
  host: SFX_HOST,
  port: SFX_PORT,
  username: SFX_USER,
  password: SFX_PASS,
  database: SFX_GLOBAL_DATABASE
)
time = DateTime.now
file_date = time.strftime('%Y-%m-%d')
last_date = nil
output_dir = "#{ROOT_DIR}/output/incremental"
File.open("#{output_dir}/last_incremental_date.txt", 'r') do |input|
  last_date = input.gets.chomp
end

current_objects = get_current_objects(client)
current_id_file = "#{output_dir}/ids_#{file_date}.txt"
File.open(current_id_file, 'w') do |output|
  current_objects.each do |object|
    output.puts(object)
  end
end
previous_objects = Set.new
prev_id_file = "#{output_dir}/ids_#{last_date}.txt"
File.open(prev_id_file, 'r') do |input|
  while line = input.gets
    previous_objects << line.chomp.to_i
  end
end

deleted_objects = previous_objects - current_objects
deleted_obj_file = "#{output_dir}/deletes_since_#{last_date}.txt"
File.open(deleted_obj_file, 'w') do |output|
  deleted_objects.each do |object|
    output.puts("(SFX)#{object}")
  end
end

new_objects = current_objects - previous_objects
changed_objects = get_changed_objects(last_date, client)
changed_obj_to_process = current_objects & changed_objects
obj_to_process = new_objects + changed_obj_to_process

other_objects = Set.new
local_objects = get_local_objects(client)
local_objects &= obj_to_process
dict = chi_dict
no_match_file = "#{output_dir}/no_match_#{file_date}.txt"
no_match_ids = Set.new
if File.exist?(no_match_file)
  File.open(no_match_file, 'r') do |input|
    while line = input.gets
      no_match_ids << line.chomp.to_i
    end
  end
else
  forced_brief_ids = get_local_brief_objects(client)
  if forced_brief_ids.size > 0
    File.open(no_match_file, 'a') do |output|
      forced_brief_ids.each do |id|
        no_match_ids << id
        output.puts(id)
      end
    end
  end
end

writer = MARC::Writer.new("#{output_dir}/matched_#{file_date}.mrc")

processed_file = "#{output_dir}/processed_#{file_date}.txt"
processed_ids = Set.new
File.open(processed_file, 'r') do |input|
  while line = input.gets
    line.chomp!
    processed_ids << line.to_i
  end
end
remaining_objects = obj_to_process - local_objects - no_match_ids - processed_ids
processed_output = File.open(processed_file, 'a')
no_match_output = File.open(no_match_file, 'a')
## There is a limit to the number
## of API calls one can make to Worldcat
## in a day
api_count = 0
remaining_objects.each do |object_id|
  break if api_count > 200_000
  result = get_rec(object_id, client)
  api_count += result[:api_count]
  case result[:rec_type]
  when 'brief_rec'
    no_match_output.puts(object_id)
  when 'issn_el'
    writer.write(result[:record])
    processed_ids << object_id
    processed_output.puts(object_id)
  when 'issn_print'
    writer.write(result[:record])
    processed_ids << object_id
    processed_output.puts(object_id)
  when 'issn_alt'
    writer.write(result[:record])
    processed_ids << object_id
    processed_output.puts(object_id)
  when 'lccn'
    writer.write(result[:record])
    processed_ids << object_id
    processed_output.puts(object_id)
  when 'lccn_alt'
    writer.write(result[:record])
    processed_ids << object_id
    processed_output.puts(object_id)
  when 'oclc'
    writer.write(result[:record])
    processed_ids << object_id
    processed_output.puts(object_id)
  when 'oclc_alt'
    writer.write(result[:record])
    processed_ids << object_id
    processed_output.puts(object_id)
  end
end
no_match_output.close
writer.close

unless local_objects.empty?
  no_match_output = File.open(no_match_file, 'a')
  local_writer = MARC::Writer.new("#{output_dir}/local_#{file_date}.mrc")
  local_objects.each do |object_id|
    result = get_local_rec(object_id, client)
    if result[:rec_type] == 'brief_rec'
      no_match_output.puts(object_id)
    else
      processed_ids << object_id
      processed_output.puts(object_id)
      local_writer.write(result[:record])
    end
  end
  no_match_output.close
  local_writer.close
end
no_match_ids = Set.new
File.open(no_match_file, 'r') do |input|
  while line = input.gets
    line.chomp!
    no_match_ids << line.to_i
  end
end
unless no_match_ids.empty?
  record_date = time.strftime('%y%m%d')
  brief_writer = MARC::Writer.new("#{output_dir}/brief_#{file_date}.mrc")
  File.open(no_match_file, 'a') do |output|
    no_match_ids.each do |object_id|
      record = process_no_match(object_id, client, record_date, dict)
      brief_writer.write(record)
      processed_ids << object_id
      processed_output.puts(object_id)
      output.puts(object_id)
    end
  end
  brief_writer.close
end
