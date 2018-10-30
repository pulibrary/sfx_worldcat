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
File.open("#{ROOT_DIR}/output/incremental/last_incremental_date.txt", 'r') do |input|
  last_date = input.gets.chomp
end

current_objects = get_current_objects(client)
current_id_file = "#{ROOT_DIR}/output/incremental/ids_#{file_date}.txt"
File.open(current_id_file, 'w') do |output|
  current_objects.each do |object|
    output.puts(object)
  end
end
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

other_objects = Set.new
local_objects = get_local_objects(client)
local_objects &= obj_to_process

unless local_objects.empty?
  local_writer = MARC::Writer.new("#{ROOT_DIR}/output/incremental/local_#{file_date}.mrc")
  local_objects.each do |object_id|
    result = get_local_rec(object_id, client)
    case result[:rec_type]
    when 'brief_rec'
      other_objects << object_id
    when 'local_rec'
      local_writer.write(result[:record])
    end
  end
  local_writer.close
end

remaining_objects = obj_to_process - local_objects

issn_el_writer = MARC::Writer.new("#{ROOT_DIR}/output/incremental/issn_el_#{file_date}.mrc")
issn_print_writer = MARC::Writer.new("#{ROOT_DIR}/output/incremental/issn_print_#{file_date}.mrc")
lccn_writer = MARC::Writer.new("#{ROOT_DIR}/output/incremental/lccn_#{file_date}.mrc")
oclc_writer = MARC::Writer.new("#{ROOT_DIR}/output/incremental/oclc_#{file_date}.mrc")
issn_alt_writer = MARC::Writer.new("#{ROOT_DIR}/output/incremental/issn_alt_#{file_date}.mrc")
lccn_alt_writer = MARC::Writer.new("#{ROOT_DIR}/output/incremental/lccn_alt_#{file_date}.mrc")
oclc_alt_writer = MARC::Writer.new("#{ROOT_DIR}/output/incremental/oclc_alt_#{file_date}.mrc")

api_count = 0
remaining_objects.each do |object_id|
  break if api_count > 60_000
  result = get_rec(object_id, client)
  api_count += result[:api_count]
  case result[:rec_type]
  when 'brief_rec'
    other_objects << object_id
  when 'issn_el'
    issn_el_writer.write(result[:record])
  when 'issn_print'
    issn_print_writer.write(result[:record])
  when 'issn_alt'
    issn_alt_writer.write(result[:record])
  when 'lccn'
    lccn_writer.write(result[:record])
  when 'lccn_alt'
    lccn_alt_writer.write(result[:record])
  when 'oclc'
    oclc_writer.write(result[:record])
  when 'oclc_alt'
    oclc_alt_writer.write(result[:record])
  end
end

issn_el_writer.close
issn_print_writer.close
lccn_writer.close
oclc_writer.close
issn_alt_writer.close
lccn_alt_writer.close
oclc_alt_writer.close

unless other_objects.empty?
  record_date = time.strftime('%Y%m%d')
  brief_writer = MARC::Writer.new("#{ROOT_DIR}/output/incremental/brief_#{file_date}.mrc")
  other_objects.each do |object_id|
    record = process_no_match(object_id, client, record_date)
    brief_writer.write(record)
  end
  brief_writer.close
end
