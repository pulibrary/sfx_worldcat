module SFXWorldcat
  include SFXWorldcat::SFX
  include SFXWorldcat::Worldcat

  def get_rec(object_id, client)
    api_count = 0
    object_identifiers = get_identifiers(object_id, client)
    return { record: nil, api_count: api_count, rec_type: 'brief_rec' } if object_identifiers.empty?
    id_types = object_identifiers.map { |arr| { type: arr['type'], sub_type: arr['sub_type'] } }
    if id_types.include?(type: 'ISSN', sub_type: 'ELECTRONIC')
      result = process_issn_el_object(object_identifiers)
      record_coll = result[0]
      api_count += result[1]
      return { record: nil, api_count: api_count, rec_type: 'brief_rec' } if record_coll.nil?
      reader = MARC::XMLReader.new(StringIO.new(record_coll))
      bib = reader.first
      bib776 = bib.fields('776')
      alt_oclc = nil
      if bib776
        bib776.each do |field|
          next unless field['i'] =~ /[Oo]nline version/
          field.subfields.each do |subfield|
            next unless subfield.value =~ /OCoLC/ && subfield.code == 'w'
            alt_oclc = subfield.value.gsub(/^\(OCoLC\)([0-9]+)$/, '\1')
          end
        end
      end
      if alt_oclc
        oclc_object = { 'type' => 'OCLC_NR', 'sub_type' => '', 'value' => alt_oclc }
        test_result = process_oclc_object([oclc_object])
        test_coll = test_result[0]
        api_count += test_result[1]
        if test_coll.nil?
          fixed = process_bib_base(bib, object_id)
          return { record: fixed, api_count: api_count, rec_type: 'issn_el' }
        else
          test_reader = MARC::XMLReader.new(StringIO.new(test_coll))
          test_bib = test_reader.first
          fixed = process_bib_base(test_bib, object_id)
          return { record: fixed, api_count: api_count, rec_type: 'issn_alt' }
        end
      else
        fixed = process_bib_base(bib, object_id)
        return { record: fixed, api_count: api_count, rec_type: 'issn_el' }
      end
    elsif id_types.include?(type: 'ISSN', sub_type: 'PRINT')
      result = process_issn_print_object(object_identifiers)
      record_coll = result[0]
      api_count += result[1]
      return { record: nil, api_count: api_count, rec_type: 'brief_rec' } if record_coll.nil?
      reader = MARC::XMLReader.new(StringIO.new(record_coll))
      bib = reader.first
      bib776 = bib.fields('776')
      alt_oclc = nil
      if bib776
        bib776.each do |field|
          next unless field['i'] =~ /[Oo]nline version/
          field.subfields.each do |subfield|
            next unless subfield.value =~ /OCoLC/ && subfield.code == 'w'
            alt_oclc = subfield.value.gsub(/^\(OCoLC\)([0-9]+)$/, '\1')
          end
        end
      end
      if alt_oclc
        oclc_object = {
          'type' => 'OCLC_NR',
          'sub_type' => '',
          'value' => alt_oclc
        }
        test_result = process_oclc_object([oclc_object])
        test_coll = test_result[0]
        api_count += test_result[1]
        if test_coll.nil?
          fixed = process_bib_base(bib, object_id)
          return { record: fixed, api_count: api_count, rec_type: 'issn_print' }
        else
          test_reader = MARC::XMLReader.new(StringIO.new(test_coll))
          test_bib = test_reader.first
          fixed = process_bib_base(test_bib, object_id)
          return { record: fixed, api_count: api_count, rec_type: 'issn_alt' }
        end
      else
        fixed = process_bib_base(bib, object_id)
        return { record: fixed, api_count: api_count, rec_type: 'issn_print' }
      end
    elsif id_types.include?(type: 'LCCN', sub_type: '')
      result = process_lccn_object(object_identifiers)
      record_coll = result[0]
      api_count += result[1]
      return { record: nil, api_count: api_count, rec_type: 'brief_rec' } if record_coll.nil?
      reader = MARC::XMLReader.new(StringIO.new(record_coll))
      bib = reader.first
      bib776 = bib.fields('776')
      alt_oclc = nil
      if bib776
        bib776.each do |field|
          next unless field['i'] =~ /[Oo]nline version/
          field.subfields.each do |subfield|
            next unless subfield.value =~ /OCoLC/ && subfield.code == 'w'
            alt_oclc = subfield.value.gsub(/^\(OCoLC\)([0-9]+)$/, '\1')
          end
        end
      end
      if alt_oclc
        oclc_object = {
          'type' => 'OCLC_NR',
          'sub_type' => '',
          'value' => alt_oclc
        }
        test_result = process_oclc_object([oclc_object])
        test_coll = test_result[0]
        api_count += test_result[1]
        if test_coll.nil?
          fixed = process_bib_base(bib, object_id)
          return { record: fixed, api_count: api_count, rec_type: 'lccn' }
        else
          test_reader = MARC::XMLReader.new(StringIO.new(test_coll))
          test_bib = test_reader.first
          fixed = process_bib_base(test_bib, object_id)
          return { record: fixed, api_count: api_count, rec_type: 'lccn_alt' }
        end
      else
        fixed = process_bib_base(bib, object_id)
        return { record: fixed, api_count: api_count, rec_type: 'lccn' }
      end
    elsif id_types.include?(type: 'OCLC_NR', sub_type: '')
      result = process_oclc_object(object_identifiers)
      record_coll = result[0]
      api_count += result[1]
      return { record: nil, api_count: api_count, rec_type: 'brief_rec' } if record_coll.nil?
      reader = MARC::XMLReader.new(StringIO.new(record_coll))
      bib = reader.first
      bib776 = bib.fields('776')
      alt_oclc = nil
      if bib776
        bib776.each do |field|
          next unless field['i'] =~ /[Oo]nline version/
          field.subfields.each do |subfield|
            next unless subfield.value =~ /OCoLC/ && subfield.code == 'w'
            alt_oclc = subfield.value.gsub(/^\(OCoLC\)([0-9]+)$/, '\1')
          end
        end
      end
      if alt_oclc
        oclc_object = { 'type' => 'OCLC_NR', 'sub_type' => '', 'value' => alt_oclc }
        test_result = process_oclc_object([oclc_object])
        test_coll = test_result[0]
        api_count += test_result[1]
        if test_coll.nil?
          fixed = process_bib_base(bib, object_id)
          return { record: fixed, api_count: api_count, rec_type: 'oclc' }
        else
          test_reader = MARC::XMLReader.new(StringIO.new(test_coll))
          test_bib = test_reader.first
          fixed = process_bib_base(test_bib, object_id)
          return { record: fixed, api_count: api_count, rec_type: 'oclc_alt' }
        end
      else
        fixed = process_bib_base(bib, object_id)
        return { record: fixed, api_count: api_count, rec_type: 'oclc' }
      end
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
