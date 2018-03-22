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
last_date = nil
File.open("#{ROOT_DIR}/output/incremental/last_incremental_date.txt", 'r') do |input|
  last_date = input.gets.chomp
end

current_objects = get_current_objects(client)
previous_objects = Set.new
prev_id_file = "#{ROOT_DIR}/output/incremental/ids_#{last_date}.txt"
File.open(prev_id_file, 'r') do |input|
  while line = input.gets
    previous_objects << line.chomp.to_i
  end
end

deleted_objects = previous_objects - current_objects
deleted_obj_file = "#{ROOT_DIR}/output/incremental/deletes_since_#{last_date}.txt"
File.open(deleted_obj_file, 'w') do |output|
  deleted_objects.each do |object|
    output.puts("(SFX)#{object}")
  end
end

new_objects = current_objects - previous_objects
changed_objects = get_changed_objects(last_date, client)
changed_obj_to_process = current_objects & changed_objects
obj_to_process = new_objects + changed_obj_to_process

local_objects = get_local_objects(client)
local_objects = local_objects & obj_to_process

remaining_objects = obj_to_process - local_objects

other_objects = Set.new
processed_ids = Set.new
issn_el_writer = MARC::Writer.new("#{ROOT_DIR}/output/incremental/issn_el_#{file_date}.mrc")
issn_print_writer = MARC::Writer.new("#{ROOT_DIR}/output/incremental/issn_print_#{file_date}.mrc")
lccn_writer = MARC::Writer.new("#{ROOT_DIR}/output/incremental/lccn_#{file_date}.mrc")
oclc_writer = MARC::Writer.new("#{ROOT_DIR}/output/incremental/oclc_#{file_date}.mrc")
issn_alt_writer = MARC::Writer.new("#{ROOT_DIR}/output/incremental/issn_alt_#{file_date}.mrc")
lccn_alt_writer = MARC::Writer.new("#{ROOT_DIR}/output/incremental/lccn_alt_#{file_date}.mrc")
oclc_alt_writer = MARC::Writer.new("#{ROOT_DIR}/output/incremental/oclc_alt_#{file_date}.mrc")

api_count = 0
remaining_objects.each do |object_id|
  break if api_count > 50_000
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
