require_relative './../lib/sfx_worldcat'
include SFXWorldcat

client = Mysql2::Client.new(
  host: SFX_HOST,
  port: SFX_PORT,
  username: SFX_USER,
  password: SFX_PASS,
  database: SFX_GLOBAL_DATABASE
)

file_date = Date.today.strftime('%Y-%m-%d')
issn_el_writer = MARC::Writer.new("#{ROOT_DIR}/output/full/issn_el_#{file_date}.mrc")
issn_print_writer = MARC::Writer.new("#{ROOT_DIR}/output/full/issn_print_#{file_date}.mrc")
lccn_writer = MARC::Writer.new("#{ROOT_DIR}/output/full/lccn_#{file_date}.mrc")
oclc_writer = MARC::Writer.new("#{ROOT_DIR}/output/full/oclc_#{file_date}.mrc")
issn_alt_writer = MARC::Writer.new("#{ROOT_DIR}/output/full/issn_alt_#{file_date}.mrc")
lccn_alt_writer = MARC::Writer.new("#{ROOT_DIR}/output/full/lccn_alt_#{file_date}.mrc")
oclc_alt_writer = MARC::Writer.new("#{ROOT_DIR}/output/full/oclc_alt_#{file_date}.mrc")

all_objects = Set.new
all_obj_file = "#{ROOT_DIR}/output/full/all_ids.txt"
if File.exist?(all_obj_file)
  File.open(all_obj_file, 'r') do |input|
    while line = input.gets
      all_objects << line.chomp.to_i
    end
  end
else
  all_objects = get_current_objects(client)
  File.open(all_obj_file, 'w') do |output|
    all_objects.each do |object|
      output.puts(object)
    end
  end
end

local_ids_file = "#{ROOT_DIR}/output/full/local_ids.txt"
local_objects = Set.new
if File.exist?(local_ids_file)
  File.open(local_ids_file, 'r') do |input|
    while line = input.gets
      local_objects << line.chomp.to_i
    end
  end
else
  local_objects = get_local_objects(client)
  local_objects &= all_objects
  File.open(local_ids_file, 'w') do |output|
    local_objects.each do |object|
      output.puts(object)
    end
  end
end

other_objects = Set.new
no_match_file = "#{ROOT_DIR}/output/full/no_match.txt"
if File.exist?(no_match_file)
  File.open(no_match_file, 'r') do |input|
    while line = input.gets
      other_objects << line.chomp.to_i
    end
  end
end

processed_ids = Set.new
processed_ids_file = "#{ROOT_DIR}/output/full/processed_ids.txt"
if File.exist?(processed_ids_file)
  File.open(processed_ids_file, 'r') do |input|
    while line = input.gets
      processed_ids << line.chomp.to_i
    end
  end
end

remaining_objects = all_objects - processed_ids - local_objects - other_objects

## There is a limit to the number
## of API calls one can make to Worldcat
## in a day
api_count = 0
remaining_objects.each do |object_id|
  break if api_count > 190_000
  result = get_rec(object_id, client)
  api_count += result[:api_count]
  case result[:rec_type]
  when 'brief_rec'
    other_objects << object_id
  when 'issn_el'
    issn_el_writer.write(result[:record])
    processed_ids << object_id
  when 'issn_print'
    issn_print_writer.write(result[:record])
    processed_ids << object_id
  when 'issn_alt'
    issn_alt_writer.write(result[:record])
    processed_ids << object_id
  when 'lccn'
    lccn_writer.write(result[:record])
    processed_ids << object_id
  when 'lccn_alt'
    lccn_alt_writer.write(result[:record])
    processed_ids << object_id
  when 'oclc'
    oclc_writer.write(result[:record])
    processed_ids << object_id
  when 'oclc_alt'
    oclc_alt_writer.write(result[:record])
    processed_ids << object_id
  end
end

issn_el_writer.close
issn_print_writer.close
lccn_writer.close
oclc_writer.close
issn_alt_writer.close
lccn_alt_writer.close
oclc_alt_writer.close

File.open(processed_ids_file, 'w') do |output|
  processed_ids.each do |object|
    output.puts(object)
  end
end

unless other_objects.empty?
  brief_writer = MARC::Writer.new("#{ROOT_DIR}/output/full/brief_#{file_date}.mrc")
  File.open(no_match_file, 'w') do |output|
    other_objects.each do |object_id|
      record = process_no_match(object_id, client, file_date)
      brief_writer.write(record)
      output.puts(object_id)
  end
  brief_writer.close
end
