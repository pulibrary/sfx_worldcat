module SFXWorldcat
  include SFXWorldcat::SFX
  include SFXWorldcat::Worldcat

  def get_rec(object_id, client)
    api_count = 0
    identifiers = get_identifiers(object_id, client)
    return { record: nil, api_count: api_count, rec_type: 'brief_rec' } if identifiers.empty?
    id_types = identifiers.map { |arr| { type: arr['type'], sub_type: arr['sub_type'] } }
    if id_types.include?(type: 'ISSN', sub_type: 'ELECTRONIC')
      result = process_issn_el_object(identifiers)
      record_coll = result[0]
      api_count += result[1]
      return { record: nil, api_count: api_count, rec_type: 'brief_rec' } if record_coll.nil?
      reader = MARC::XMLReader.new(StringIO.new(record_coll))
      bib = reader.first
      rec_type = 'issn_el'
      preferred_rec = bib
      alt_oclc = get_alt_oclc(bib)
      if alt_oclc
        oclc_object = { 'type' => 'OCLC_NR', 'sub_type' => '', 'value' => alt_oclc }
        test_result = process_oclc_object([oclc_object])
        test_coll = test_result[0]
        api_count += test_result[1]
        unless test_coll.nil?
          test_reader = MARC::XMLReader.new(StringIO.new(test_coll))
          test_bib = test_reader.first
          preferred_rec = evaluate_alt_record(bib, test_bib)
          rec_type = 'issn_alt' if preferred_rec == test_bib
        end
      end
      fixed = process_bib_base(preferred_rec, object_id)
      return { record: fixed, api_count: api_count, rec_type: rec_type }
    elsif id_types.include?(type: 'ISSN', sub_type: 'PRINT')
      result = process_issn_print_object(identifiers)
      record_coll = result[0]
      api_count += result[1]
      return { record: nil, api_count: api_count, rec_type: 'brief_rec' } if record_coll.nil?
      reader = MARC::XMLReader.new(StringIO.new(record_coll))
      bib = reader.first
      rec_type = 'issn_print'
      preferred_rec = bib
      alt_oclc = get_alt_oclc(bib)
      if alt_oclc
        oclc_object = { 'type' => 'OCLC_NR', 'sub_type' => '', 'value' => alt_oclc }
        test_result = process_oclc_object([oclc_object])
        test_coll = test_result[0]
        api_count += test_result[1]
        unless test_coll.nil?
          test_reader = MARC::XMLReader.new(StringIO.new(test_coll))
          test_bib = test_reader.first
          preferred_rec = evaluate_alt_record(bib, test_bib)
          rec_type = 'issn_alt' if preferred_rec == test_bib
        end
      end
      fixed = process_bib_base(preferred_rec, object_id)
      return { record: fixed, api_count: api_count, rec_type: rec_type }
    elsif id_types.include?(type: 'LCCN', sub_type: '')
      result = process_lccn_object(identifiers)
      record_coll = result[0]
      api_count += result[1]
      return { record: nil, api_count: api_count, rec_type: 'brief_rec' } if record_coll.nil?
      reader = MARC::XMLReader.new(StringIO.new(record_coll))
      bib = reader.first
      rec_type = 'lccn'
      preferred_rec = bib
      alt_oclc = get_alt_oclc(bib)
      if alt_oclc
        oclc_object = { 'type' => 'OCLC_NR', 'sub_type' => '', 'value' => alt_oclc }
        test_result = process_oclc_object([oclc_object])
        test_coll = test_result[0]
        api_count += test_result[1]
        unless test_coll.nil?
          test_reader = MARC::XMLReader.new(StringIO.new(test_coll))
          test_bib = test_reader.first
          preferred_rec = evaluate_alt_record(bib, test_bib)
          rec_type = 'lccn_alt' if preferred_rec == test_bib
        end
      end
      fixed = process_bib_base(preferred_rec, object_id)
      return { record: fixed, api_count: api_count, rec_type: rec_type }
    elsif id_types.include?(type: 'OCLC_NR', sub_type: '')
      result = process_oclc_object(identifiers)
      record_coll = result[0]
      api_count += result[1]
      return { record: nil, api_count: api_count, rec_type: 'brief_rec' } if record_coll.nil?
      reader = MARC::XMLReader.new(StringIO.new(record_coll))
      bib = reader.first
      rec_type = 'oclc'
      preferred_rec = bib
      alt_oclc = get_alt_oclc(bib)
      if alt_oclc
        oclc_object = { 'type' => 'OCLC_NR', 'sub_type' => '', 'value' => alt_oclc }
        test_result = process_oclc_object([oclc_object])
        test_coll = test_result[0]
        api_count += test_result[1]
        unless test_coll.nil?
          test_reader = MARC::XMLReader.new(StringIO.new(test_coll))
          test_bib = test_reader.first
          preferred_rec = evaluate_alt_record(bib, test_bib)
          rec_type = 'oclc_alt' if preferred_rec == test_bib
        end
      end
      fixed = process_bib_base(preferred_rec, object_id)
      return { record: fixed, api_count: api_count, rec_type: rec_type }
    end
    { record: nil, api_count: api_count, rec_type: 'brief_rec' }
  end

  def get_local_rec(object_id, client)
    api_count = 0
    oclc_no = get_local_identifier(object_id, client)
    oclc_object = { 'type' => 'OCLC_NR', 'sub_type' => '', 'value' => oclc_no }
    result = process_oclc_object([oclc_object])
    record_coll = result[0]
    api_count += result[1]
    return { record: nil, api_count: api_count, rec_type: 'brief_rec' } if record_coll.nil?
    local_reader = MARC::XMLReader.new(StringIO.new(record_coll))
    bib = local_reader.first
    fixed = process_bib_base(bib, object_id)
    { record: fixed, api_count: api_count, rec_type: 'local_rec' }
  end
end
