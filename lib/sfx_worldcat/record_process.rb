require 'marc'
require 'marc_cleanup'

module SFXWorldcat
  include SFXWorldcat::SFX

  def process_related_objects(object_id, client)
    related_objects = get_related_objects(object_id, client)
    return related_objects if related_objects.empty?
    fields = []
    related_objects.each do |object|
      language = object[:language]
      title = get_related_title(object[:object_id], language, client)
      next unless title
      issn = get_related_issn(object[:object_id], client)
      ind1 = '0'
      tag, ind2 = get_tag_ind2_from_relation_type(object[:relation_type])
      next unless tag
      field = MARC::DataField.new(tag, ind1, ind2, ['t', title])
      field.append(MARC::Subfield.new('x', issn)) if issn
      fields << field
    end
    fields.sort! { |x, y| x.tag.to_i <=> y.tag.to_i }
    fields
  end

  ### Return array of title hash
  def get_titles(object_id, language, client)
    titles = get_raw_titles(object_id, client)
    titles = if cjkr_languages.include?(language)
               process_cjkr_titles(titles, language)
             else
               process_noncjkr_titles(titles, language)
             end
    titles
  end

  def char_cleanup_array
    [
      ["\u00c3\u00a2\u00e2\u201a\u00ac\u00e2\u20ac\u0153", "\u002d"],
      ["\u00c3\u201e\u00c6\u2019\u00c3\u2026\u00c2\u00a3", "\u0103\u0163"],
      ["\u00c3\u201e\\\\u0078\u0038\u0044", "\u010d"],
      ["\u00e1\u00b8\u00a4", "\u1e24"],
      ["\u00e1\u00b8\u00a5", "\u1e25"],
      ["\u00e1\u00b9\u00a3", "\u1e63"],
      ["\u00e1\u00b9\u00ad", "\u1e6d"],
      ["\u00e1\u00b9\u00af", "\u1e6f"],
      ["\u00ef\u00a2\u0095", "\u00fc"],
      ["\u00e2\u0080\u009e", "\u0022"],
      ["\u00e2\u0080\u009d", "\u0022"],
      ["\u00e2\u0080\u009c", "\u0022"],
      ["\u00e2\u0080\u0093", "\u002d"],
      ["\u00ed\u0095\u009c", "\ud55c"],
      ["\u00ea\u00b5\u00ad", "\uad6d"],
      ["\u00eb\u00a9\u0080", "\uba40"],
      ["\u00ed\u008b\u00b0", "\ud2f0"],
      ["\u00eb\u00af\u00b8", "\ubbf8"],
      ["\u00eb\u0094\u0094", "\ub514"],
      ["\u00ec\u0096\u00b4", "\uc5b4"],
      ["\u00ed\u0095\u0099", "\ud559"],
      ["\u00ed\u009a\u008c", "\ud68c"],
      ["\u0065\u0094", "\u00e4"],
      ["\u00bf\u006f", "\u006f\u0304"],
      ["\u00c4\u0083", "\u0103"],
      ["\u00c4\u0192", "\u0103"],
      ["\u05b4\u0192", "\u0103"],
      ["\u00c3\u0081", "\u00c1"],
      ["\u00c3\u0082", "\u00c2"],
      ["\u00c3\u0083", "\u00c3"],
      ["\u00c3\u0084", "\u00c4"],
      ["\u00c3\u0085", "\u00c5"],
      ["\u00c3\u0086", "\u00c6"],
      ["\u00c3\u0087", "\u00c7"],
      ["\u00c3\u0088", "\u00c8"],
      ["\u00c3\u0089", "\u00c9"],
      ["\u00c3\u008a", "\u00ca"],
      ["\u00c3\u008b", "\u00cb"],
      ["\u00c3\u008c", "\u00cc"],
      ["\u00c3\u008d", "\u00cd"],
      ["\u00c3\u008e", "\u00ce"],
      ["\u00c3\u008f", "\u00cf"],
      ["\u00c3\u0090", "\u00d0"],
      ["\u00c3\u0091", "\u00d1"],
      ["\u00c3\u0092", "\u00d2"],
      ["\u00c3\u0093", "\u00d3"],
      ["\u00c3\u0094", "\u00d4"],
      ["\u00c3\u0095", "\u00d5"],
      ["\u00c3\u0096", "\u00d6"],
      ["\u00c3\u0097", "\u00d7"],
      ["\u00c3\u0098", "\u00d8"],
      ["\u00c3\u0099", "\u00d9"],
      ["\u00c3\u009a", "\u00da"],
      ["\u00c3\u009b", "\u00db"],
      ["\u00c3\u009c", "\u00dc"],
      ["\u00c3\u009d", "\u00dd"],
      ["\u00c3\u009e", "\u00de"],
      ["\u00c3\u009f", "\u00df"],
      ["\u00c3\u00a0", "\u00e0"],
      ["\u00c3\u00a1", "\u00e1"],
      ["\u00c3\u00a2", "\u00e2"],
      ["\u00c3\u00a3", "\u00e3"],
      ["\u00c3\u00a4", "\u00e4"],
      ["\u00c3\u00a5", "\u00e5"],
      ["\u00c3\u00a6", "\u00e6"],
      ["\u00c3\u00a7", "\u00e7"],
      ["\u00c3\u00a8", "\u00e8"],
      ["\u00c3\u00a9", "\u00e9"],
      ["\u00c3\u00aa", "\u00ea"],
      ["\u00c3\u00ab", "\u00eb"],
      ["\u00c3\u00ac", "\u00ec"],
      ["\u00c3\u00ad", "\u00ed"],
      ["\u00c3\u00ae", "\u00ee"],
      ["\u00c3\u00af", "\u00ef"],
      ["\u00c3\u00b0", "\u00f0"],
      ["\u00c3\u00b1", "\u00f1"],
      ["\u00c3\u00b3", "\u00f3"],
      ["\u00c3\u00b4", "\u00f4"],
      ["\u00c3\u00b5", "\u00f5"],
      ["\u00c3\u00b6", "\u00f6"],
      ["\u00c3\u00b7", "\u00f7"],
      ["\u00c3\u00b8", "\u00f8"],
      ["\u00c3\u00b9", "\u00f9"],
      ["\u00c3\u00ba", "\u00fa"],
      ["\u00c3\u00bb", "\u00fb"],
      ["\u00c3\u00bc", "\u00fc"],
      ["\u00c3\u00bd", "\u00fd"],
      ["\u00c3\u00be", "\u00fe"],
      ["\u00c3\u00bf", "\u00ff"],
      ["\u0065\u0098", "\u00e8"],
      ["\u00c3\u2030", "\u00e9"],
      ["\u00d7\u0099", "\u00e9"],
      ["\u0065\u0099", "\u00e9"],
      ["\u0065\u009a", "\u00ea"],
      ["\u0065\u0097", "\u00e7"],
      ["\u00c4\u008d", "\u010d"],
      ["\u0065\u009d", "\u00ed"],
      ["\u00c3\u008d", "\u0049\u0301"],
      ["\u00c5\u017e", "\u015e"],
      ["\u00c5\u009e", "\u015e"],
      ["\u00c5\u00a3", "\u0163"],
      ["\u00c3\u00ba", "\u0075\u0301"],
      ["\u00c3\u0161", "\u00da"],
      ["\u00c5\u009f", "\u015f"],
      ["\u00c3\u009f", "\u0073\u0073"],
      ["\u00d0\u0093", "\u0413"],
      ["\u00d0\u0094", "\u0414"],
      ["\u00d0\u0095", "\u0415"],
      ["\u00d0\u0096", "\u0416"],
      ["\u00d0\u0097", "\u0417"],
      ["\u00d0\u0098", "\u0418"],
      ["\u00d0\u0099", "\u0419"],
      ["\u00d0\u009a", "\u041a"],
      ["\u00d0\u009b", "\u041b"],
      ["\u00d0\u009c", "\u041c"],
      ["\u00d0\u009d", "\u041d"],
      ["\u00d0\u00a3", "\u0423"],
      ["\u00d0\u00a4", "\u0424"],
      ["\u00d0\u00a5", "\u0425"],
      ["\u00d0\u00a6", "\u0426"],
      ["\u00d0\u00a7", "\u0427"],
      ["\u00d0\u00a8", "\u0428"],
      ["\u00d0\u00a9", "\u0429"],
      ["\u00d0\u00aa", "\u042a"],
      ["\u00d0\u00ab", "\u042b"],
      ["\u00d0\u00ac", "\u042c"],
      ["\u00d0\u00ad", "\u042d"],
      ["\u00d0\u00ae", "\u042e"],
      ["\u00d0\u00af", "\u042f"],
      ["\u00d0\u00b0", "\u0430"],
      ["\u00d0\u00b1", "\u0431"],
      ["\u00d0\u00b2", "\u0432"],
      ["\u00d0\u00b3", "\u0433"],
      ["\u00d0\u00b4", "\u0434"],
      ["\u00d0\u00b5", "\u0435"],
      ["\u00d0\u00b6", "\u0436"],
      ["\u00d0\u00b7", "\u0437"],
      ["\u00d0\u00b8", "\u0438"],
      ["\u00d0\u00b9", "\u0439"],
      ["\u00d0\u00ba", "\u043a"],
      ["\u00d0\u00bb", "\u043b"],
      ["\u00d0\u00bc", "\u043c"],
      ["\u00d0\u00bd", "\u043d"],
      ["\u00d0\u00be", "\u043e"],
      ["\u00d0\u00bf", "\u043f"],
      ["\u00d1\u0080", "\u0440"],
      ["\u00d1\u0081", "\u0441"],
      ["\u00d1\u0082", "\u0442"],
      ["\u00d1\u0083", "\u0443"],
      ["\u00d1\u0084", "\u0444"],
      ["\u00d1\u0085", "\u0445"],
      ["\u00d1\u0086", "\u0446"],
      ["\u00d1\u0087", "\u0447"],
      ["\u00d1\u0088", "\u0448"],
      ["\u00d1\u0089", "\u0449"],
      ["\u00d1\u008a", "\u044a"],
      ["\u00d1\u008b", "\u044b"],
      ["\u00d1\u008c", "\u044c"],
      ["\u00d1\u009a", "\u045a"],
      ["\u05b3\u00bc", "\u00fc"],
      ["\\?\u0081", "\u0101"],
      ["\u00c4\u0081", "\u0101"],
      ["\u00c4\u0085", "\u0105"],
      ["\u00c4\u0086", "\u0106"],
      ["\u00c4\u0087", "\u0107"],
      ["\u00c4\u0088", "\u0108"],
      ["\u00c4\u0089", "\u0109"],
      ["\u00c4\u008a", "\u010a"],
      ["\u00c4\u008b", "\u010b"],
      ["\u00c4\u008c", "\u010c"],
      ["\u00c4\u008d", "\u010d"],
      ["\u00c4\u008e", "\u010e"],
      ["\u00c4\u008f", "\u010f"],
      ["\u00c4\u0090", "\u0110"],
      ["\u00c4\u0091", "\u0111"],
      ["\u00c4\u0099", "\u0119"],
      ["\u05b4\u009f", "\u011f"],
      ["\u00c4\u00a1", "\u0121"],
      ["\\?\u00ab", "\u012b"],
      ["\u00c5\u0081", "\u0141"],
      ["\u00c5\u0082", "\u0142"],
      ["\u00c5\u0083", "\u0143"],
      ["\u00c5\u0084", "\u0144"],
      ["\u00c5\u0085", "\u0145"],
      ["\u00c5\u009a", "\u015a"],
      ["\u00c5\u009b", "\u015b"],
      ["\u00c5\u00ab", "\u016b"],
      ["\u00c5\u00be", "\u017e"],
      ["\u00c5\u00a1", "\u0161"],
      ["\u00c6\u00b0", "\u01b0"],
      ["\u00c7\u00a6", "\u01e6"],
      ["\u00c7\u00a7", "\u01e7"],
      ["\u00ca\u00bf", "\u02bb"],
      ["\u05b3\u00ac", "\u00ec"],
      ["\u05b3\u00ad", "\u00ed"],
      ["\u05b3\u00ae", "\u00ee"],
      ["\u05b3\u00af", "\u00ef"],
      ["\u05b4\u0081", "\u0101"],
      ["\u00c4\u0081", "\u0101"],
      ["\u05b4\u0082", "\u0102"],
      ["\u05b4\u0083", "\u0103"],
      ["\u05b4\u0084", "\u0104"],
      ["\u05b4\u0085", "\u0105"],
      ["\u05b4\u0086", "\u0106"],
      ["\u05b4\u0087", "\u0107"],
      ["\u05b4\u0088", "\u0108"],
      ["\u05b4\u0089", "\u0109"],
      ["\u05b4\u008a", "\u010a"],
      ["\u05b4\u008b", "\u010b"],
      ["\u05b4\u008c", "\u010c"],
      ["\u05b4\u008d", "\u010d"],
      ["\u05b4\u008e", "\u010e"],
      ["\u05b4\u008f", "\u010f"],
      ["\u00c4\u009f", "\u011f"],
      ["\u00c4\u00ab", "\u012b"],
      ["\u05b4\u00ab", "\u012b"],
      ["\u05b4\u00b0", "\u0130"],
      ["\u00c4\u00b1", "\u0131"],
      ["\u05b5\u009f", "\u015e"],
      ["\u05b5\u00ab", "\u016b"],
      ["\u05ba\u00b9", "\u02b9"],
      ["\u00ca\u00bf", "\u02bf"],
      ["\u0b5c\u2019", "\u0312"],
      ["\u05c0\u2022", "\u0415"],
      ["\u05c0\u2014", "\u0417"],
      ["\u05c0\u009d", "\u041d"],
      ["\u05c0\u009f", "\u041f"],
      ["\u05c0\u00b0", "\u0430"],
      ["\u05c0\u00b1", "\u0431"],
      ["\u05c0\u00b2", "\u0432"],
      ["\u05c0\u00b3", "\u0433"],
      ["\u05c0\u00b4", "\u0434"],
      ["\u05c0\u00b5", "\u0435"],
      ["\u05c0\u00b6", "\u0436"],
      ["\u05c0\u00b7", "\u0437"],
      ["\u05c0\u00b8", "\u0438"],
      ["\u05c0\u00b9", "\u0439"],
      ["\u05c0\u00bb", "\u043b"],
      ["\u05c0\u00bc", "\u043c"],
      ["\u05c0\u00bd", "\u043d"],
      ["\u05c0\u00be", "\u043e"],
      ["\u05c0\u00f7", "\u043a"],
      ["\u05c1\u0081", "\u0441"],
      ["\u05c1\u0192", "\u0443"],
      ["\u05c1\u201a", "\u0442"],
      ["\u05c1\u2021", "\u0447"],
      ["\u05c1\u2026", "\u0445"],
      ["\u05c1\u2039", "\u044b"],
      ["\u00cc\u0081", "\u0301"],
      ["\u00cc\u0084", "\u0304"],
      ["\u00cc\u008c", "\u030c"],
      ["\u00cc\u009c", "\u031c"],
      ["\u0092", "'"],
      ["\u0098", ''],
      ["\u009c", ''],
      ["\u00bb", '"'],
      ["\u0094", ''],
      ["\u05d4", "\u00e4"],
      ["\u05d7", "\u00e7"],
      ["\u05d8", "\u00e8"],
      ["\u05d9", "\u00e9"],
      ["\u05da", "\u00ea"],
      ["\u05dd", "\u00ed"],
      ["\u2013", "\u002d"],
      ["\uf895", "\u00fc"]
    ]
  end

  def process_noncjkr_titles(titles, language)
    fixed_titles = []
    titles.each do |title|
      title[:value] = noncjkr_string_value_cleanup(title[:value], language)
      fixed_titles << title
    end
    fixed_titles.uniq
  end

  def process_cjkr_titles(titles, language)
    fixed_titles = []
    titles.each do |title|
      next unless title[:value]
      if title[:value] =~ /[\u0080-\u009f]/
        title[:value] = cjkr_string_value_cleanup(title[:value], language)
      end
      fixed_titles << title
    end
    fixed_titles.uniq
  end

  def noncjkr_string_value_cleanup(string, language)
    return nil unless string
    fixed_value = string
    char_cleanup_array.each do |array|
      next if language == 'heb' && array[0] =~ /[\u0591-\u05f4]/
      fixed_value.gsub!(/#{array[0]}/, array[1])
    end
    fixed_value
  end

  def cjkr_string_value_cleanup(string, language)
    return nil unless string
    fixed_value = string
    fixed_value = fixed_value.gsub(/[ ]+/, "\u00a0") unless language == 'rus'
    codepoint_array = fixed_value.codepoints
    fixed_value = codepoint_array.pack('c*').force_encoding('UTF-8')
    fixed_value
  end

  ### Return array of publisher hash
  def get_publishers(object_id, language, client)
    publishers = get_raw_publishers(object_id, client)
    publishers = if cjkr_languages.include? language
                   process_cjkr_publishers(publishers, language)
                 else
                   process_noncjkr_publishers(publishers, language)
                 end
    publishers
  end

  def process_cjkr_publishers(publishers, language)
    fixed_publishers = []
    publishers.each do |publisher|
      if publisher[:name] =~ /[\u0080-\u009f]/
        publisher[:name] = cjkr_string_value_cleanup(publisher[:name], language)
      end
      if publisher[:place] =~ /[\u0080-\u009f]/
        publisher[:place] = cjkr_string_value_cleanup(publisher[:place], language)
      end
      fixed_publishers << publisher
    end
    fixed_publishers.uniq
  end

  def process_noncjkr_publishers(publishers, language)
    fixed_publishers = []
    publishers.each do |publisher|
      publisher[:name] = noncjkr_string_value_cleanup(publisher[:name], language)
      publisher[:place] = noncjkr_string_value_cleanup(publisher[:place], language)
      fixed_publishers << publisher
    end
    fixed_publishers.uniq
  end

  def process_main_author(main_author)
    return nil unless main_author
    tag = nil
    ind1 = ''
    ind2 = ' '
    field_value = main_author[:name]
    case main_author[:type]
    when 'PERSONAL'
      tag = '100'
      case main_author[:format]
      when 'FORENAME' || nil
        ind1 = '0'
      when 'SURNAME'
        ind1 = '1'
      when 'FAMILY_NAME'
        ind1 = '3'
      end
    when 'CORPORATE'
      tag = '110'
      case main_author[:format]
      when 'INVERTED'
        ind1 = '0'
      when 'JURISDICTION'
        ind1 = '1'
      when 'DIRECT_ORDER'
        ind1 = '2'
      end
    when 'MEETING'
      tag = '111'
      case main_author[:format]
      when 'INVERTED'
        ind1 = '0'
      when 'JURISDICTION'
        ind1 = '1'
      when 'DIRECT_ORDER'
        ind1 = '2'
      end
    end
    return nil unless tag
    field = MARC::DataField.new(tag, ind1, ind2, ['a', field_value])
    field
  end

  def process_add_author(add_author)
    tag = nil
    ind1 = ''
    ind2 = ' '
    field_value = add_author[:name]
    case add_author[:type]
    when 'PERSONAL'
      tag = '700'
      case main_author[:format]
      when 'FORENAME'
        ind1 = '0'
      when 'SURNAME'
        ind1 = '1'
      when 'FAMILY_NAME'
        ind1 = '3'
      end
    when 'CORPORATE'
      tag = '710'
      case main_author[:format]
      when 'INVERTED'
        ind1 = '0'
      when 'JURISDICTION'
        ind1 = '1'
      when 'DIRECT_ORDER'
        ind1 = '2'
      end
    when 'MEETING'
      tag = '711'
      case main_author[:format]
      when 'INVERTED'
        ind1 = '0'
      when 'JURISDICTION'
        ind1 = '1'
      when 'DIRECT_ORDER'
        ind1 = '2'
      end
    end
    return nil unless tag
    field = MARC::DataField.new(tag, ind1, ind2, ['a', field_value])
    field
  end

  def process_main_title(main_title)
    tag = '245'
    ind1 = '0'
    ind2 = '0'
    unless main_title.nil?
      ind2 = main_title[:non_filing].nil? ? 0 : main_title[:non_filing]
      ind2 = 0 if ind2 > 9
      ind2 = ind2.to_s
    end
    field_value = main_title.nil? ? '[no title given]' : main_title[:value]
    field = MARC::DataField.new(tag, ind1, ind2, ['a', field_value], ['h', '[electronic resource]'])
    field
  end

  def process_alt_title(alt_title)
    tag = '246'
    ind1 = '1'
    ind2 = ' '
    field_value = alt_title[:value]
    field_value = field_value[alt_title[:non_filing].to_i..-1] if alt_title[:non_filing]
    field = MARC::DataField.new(tag, ind1, ind2, ['a', field_value])
    field
  end

  def process_publishers(publishers)
    return nil if publishers.empty?
    publisher = publishers.first
    tag = '264'
    ind1 = ' '
    ind2 = '1'
    pub_subfields = []
    pub_subfields << MARC::Subfield.new('a', publisher[:place]) unless publisher[:place].nil? || publisher[:place].empty?
    pub_subfields << MARC::Subfield.new('b', publisher[:name]) unless publisher[:name].nil? || publisher[:name].empty?
    pub_subfields << MARC::Subfield.new('c', publisher[:date]) unless publisher[:date].nil? || publisher[:date].empty?
    return nil if pub_subfields.empty?
    pub_field = MARC::DataField.new(tag, ind1, ind2)
    pub_subfields.each do |subfield|
      pub_field.append(subfield)
    end
    pub_field
  end

  def issn_rec_test(record_coll, issn)
    return record_coll if record_coll.nil?
    reader = MARC::XMLReader.new(StringIO.new(record_coll))
    target_record = reader.each do |record|
      break record if (record['040']['b'].nil? || record['040']['b'] == 'eng') && (record['022']['a'] == issn || record['022']['l'] == issn)
    end
    record_coll = target_record.nil? ? nil : target_record.to_xml.to_s
    record_coll
  end

  def lccn_rec_test(record_coll, lccn)
    return record_coll if record_coll.nil?
    test_lccn = lccn.gsub(/[^0-9a-zA-Z]/, '')
    reader = MARC::XMLReader.new(StringIO.new(record_coll))
    target_record = reader.each do |record|
      break record if (record['040']['b'].nil? || record['040']['b'] == 'eng') &&
        record['010']['a'].gsub(/[^0-9a-zA-Z]/, '') == test_lccn
    end
    record_coll = target_record.nil? ? nil : target_record.to_xml.to_s
    record_coll
  end

  def fields_to_delete
    %w[
      003
      006
      007
      015
      016
      029
      035
      037
      049
      055
      060
      070
      071
      072
      084
      090
      263
      265
      300
      336
      337
      338
      506
      510
      516
      538
      583
      653
      658
      752
      850
      853
      863
      856
      866
      891
    ]
  end

  ## Sort by first digit of tag;
  ## place 090 before any fields right after that;
  ## same with 856, 33x, 856, and 880
  def sort_fields(bib)
    index_090 = bib.fields.index { |field| field.tag.to_i > 90 }
    index_33x = bib.fields.index { |field| field.tag.to_i > 338 }
    index_856 = bib.fields.index { |field| field.tag.to_i > 856 }
    index_880 = bib.fields.index { |field| field.tag.to_i > 880 }
    f0xx = bib.fields('001'..'099')
    new_rec = MARC::Record.new
    new_rec.leader = bib.leader
    bib.fields('001'..'089').each do |field|
      new_rec.append(field)
    end
    bib.fields('090').each do |field|
      new_rec.append(field)
    end
    bib.fields('091'..'099').each do |field|
      new_rec.append(field)
    end
    bib.fields('100'..'199').each do |field|
      new_rec.append(field)
    end
    bib.fields('200'..'299').each do |field|
      new_rec.append(field)
    end
    bib.fields('300'..'335').each do |field|
      new_rec.append(field)
    end
    bib.fields('336'..'338').each do |field|
      new_rec.append(field)
    end
    bib.fields('339'..'399').each do |field|
      new_rec.append(field)
    end
    bib.fields('400'..'499').each do |field|
      new_rec.append(field)
    end
    bib.fields('500'..'599').each do |field|
      new_rec.append(field)
    end
    bib.fields('600'..'699').each do |field|
      new_rec.append(field)
    end
    bib.fields('700'..'799').each do |field|
      new_rec.append(field)
    end
    bib.fields('800'..'855').each do |field|
      new_rec.append(field)
    end
    bib.fields('856').each do |field|
      new_rec.append(field)
    end
    bib.fields('857'..'879').each do |field|
      new_rec.append(field)
    end
    bib.fields('880').each do |field|
      new_rec.append(field)
    end
    bib.fields('881'..'999').each do |field|
      new_rec.append(field)
    end
    new_rec
  end

  def process_bib_base(bib, object_id)
    is_match = bib['003'].nil? || bib['003'].value != 'SFX'
    bib = field_delete(fields_to_delete, bib)
    bib = field_delete(('900'..'999').to_a, bib)
    oclc_no = bib['001'].value
    bib['001'].value = object_id.to_s
    bib.fields.insert(1, MARC::ControlField.new('003', 'SFX'))
    bib.fields.insert(2, MARC::ControlField.new('006', 'm     o  d |||||||'))
    bib.fields.insert(3, MARC::ControlField.new('007', 'cr |n|||||||||'))
    bib = process_050(bib)
    bib = process_082(bib)
    bib = process_130(bib)
    bib = process_210(bib)
    bib = process_222(bib)
    bib = append_245h(bib)
    bib = process_246(bib)
    bib = process_533(bib)
    bib = process_530(bib)
    bib = process_6xx(bib)
    bib = process_776(bib)
    bib = process_880(bib)
    url = %(https://getit.princeton.edu/resolve?url_ver=Z39.88-2004
      &ctx_ver=Z39.88-2004
      &ctx_enc=info:ofi/enc:UTF-8
      &rfr_id=info:sid/sfxit.com:opac_856
      &url_ctx_fmt=info:ofi/fmt:kev:mtx:ctx
      &sfx.ignore_date_threshold=1
      &rft.object_id=#{object_id}
      &svc_val_fmt=info:ofi/fmt:kev:mtx:sch_svc&).gsub(/[\s]+/, '')
    bib.append(MARC::DataField.new('090', ' ', ' ', ['a', 'Electronic Resource']))
    bib.append(MARC::DataField.new('336', ' ', ' ', %w[a text], %w[b txt], %w[2 rdacontent]))
    bib.append(MARC::DataField.new('337', ' ', ' ', %w[a computer], %w[b c], %w[2 rdamedia]))
    bib.append(MARC::DataField.new('338', ' ', ' ', ['a', 'online resource'], %w[b cr], %w[2 rdacarrier]))
    bib.append(MARC::DataField.new('856', '4', '0', %W[u #{url}], ['z', "View Princeton's online holdings"]))
    bib.append(MARC::DataField.new('910', ' ', ' ', %W[b (OCoLC)#{oclc_no}])) if is_match
    bib = bad_utf8_fix(bib)
    bib = leaderfix(bib)
    bib = extra_space_fix(bib)
    bib = composed_chars_normalize(bib)
    bib = tab_newline_fix(bib)
    bib = empty_subfield_fix(bib)
    bib = fix_008(bib)
    bib = sort_fields(bib)
    bib
  end

  def append_245h(bib)
    return bib unless bib['245']
    fixed = bib
    bib245 = fixed['245']
    bib880 = fixed.fields('880')
    bib880.select! { |field| field['6'] =~ /^245-/ }
    fields_to_update = [bib245] + bib880
    add_subfh_to_fields(fixed, fields_to_update)
  end

  def add_subfh_to_fields(bib, fields)
    fields.each do |field|
      subf_h = MARC::Subfield.new('h', '[electronic resource]')
      field_index = bib.fields.index(field)
      field.subfields.delete_if { |subfield| subfield.code == 'h' }
      subf_codes = ''
      field.subfields.each { |subfield| subf_codes << subfield.code }
      subfa_index = subf_codes.index('a')
      non_6anp_index = subf_codes.index(/[^6anp]/)
      final_chars_subfa = field['a'][-2, 2]
      if subf_codes =~ /^(6)?a[^np]|^(6)?a$/
        case final_chars_subfa
        when /[^.]\./
          bib.fields[field_index].subfields[subfa_index].value = field['a'][0..-2]
          subf_h.value << '.'
        when /[^ ][:\/;=]/
          subf_h.value << " #{field['a'][-1]}"
          bib.fields[field_index].subfields[subfa_index].value = field['a'][0..-2]
        when / [:\/;=]/
          subf_h.value << final_chars_subfa
          bib.fields[field_index].subfields[subfa_index].value = field['a'][0..-3]
        end
      end
      if non_6anp_index
        bib.fields[field_index].subfields.insert(non_6anp_index, subf_h)
      else
        bib.fields[field_index].subfields << subf_h
      end
    end
    bib
  end

  def process_050(bib)
    return bib if bib.fields('050').empty?
    fixed = bib
    target_fields = fixed.fields('050')
    target_fields.each do |field|
      next unless field.indicator2 == ' '
      field_index = fixed.fields.index(field)
      fixed.fields[field_index].indicator2 = '4'
    end
    fixed
  end

  def process_082(bib)
    return bib if bib.fields('082').empty?
    valid_ind1 = %w[0 1 7]
    fixed = bib
    target_fields = fixed.fields('082')
    target_fields.each do |field|
      next if valid_ind1.include? field.indicator1
      field_index = fixed.fields.index(field)
      fixed.fields[field_index].indicator1 = '0'
    end
    fixed
  end

  def process_130(bib)
    return bib unless bib['130'] && bib['130']['a']
    bib['130']['a'].gsub!(/CD\-ROM/, 'Online')
    bib
  end

  def process_210(bib)
    return bib if bib.fields('210').empty?
    fixed = bib
    target_fields = fixed.fields('210')
    target_fields.each do |field|
      next unless [field.indicator1, field.indicator2] == [' ', ' ']
      field_index = fixed.fields.index(field)
      fixed.fields[field_index].indicator1 = '0'
      fixed.fields[field_index].indicator2 = '0'
    end
    fixed
  end

  def process_222(bib)
    return bib unless bib['222'] && bib['222']['b']
    bib['222']['b'].gsub!(/CD\-ROM/, 'Online')
    bib
  end

  def process_246(bib)
    return bib if bib.fields('246').empty?
    valid_ind1 = %w[0 1 2 3]
    target_fields = bib.fields('246')
    field_array = []
    target_fields.each do |field|
      field_index = bib.fields.index(field)
      bib.fields[field_index].indicator1 = '1' unless valid_ind1.include? field.indicator1
      field_string = ''
      field.subfields.each do |subfield|
        next if subfield.code == '6'
        field_string << subfield.code
        field_string << subfield.value
      end
      if field_array.include?(field_string)
        bib.fields.delete_at(field_index)
      else
        field_array << field_string
      end
    end
    bib
  end

  def process_533(bib)
    return bib if bib.fields('533').empty?
    fixed = bib
    target_fields = fixed.fields('533')
    target_fields.each do |field|
      next unless field.to_s =~ /Hathi/
      field_index = fixed.fields.index(field)
      fixed.fields.delete_at(field_index)
    end
    fixed
  end

  def process_530(bib)
    return bib if bib.fields('530').empty?
    fixed = bib
    target_fields = fixed.fields('530')
    target_fields.each do |field|
      next unless field.to_s =~ /online|electronic/
      field_index = fixed.fields.index(field)
      fixed.fields.delete_at(field_index)
    end
    fixed
  end

  def process_6xx(bib)
    return bib if bib.fields('600'..'699').empty?
    wanted_sources = %w[lcgft fast]
    subject_fields = bib.fields('600'..'699')
    subject_fields.each do |field|
      del = false
      if %w[0 7].include?(field.indicator2)
        if field.indicator2 == '7' && !wanted_sources.include?(field['2'])
          del = true
        elsif field['a'] =~ /^[Ee]lectronic journals/
          del = true
        end
      else
        del = true
      end
      if del
        field_index = bib.fields.index(field)
        bib.fields.delete_at(field_index)
      end
    end
    bib
  end

  def process_776(bib)
    return bib if bib.fields('776').empty?
    valid_ind1 = %w[0 1]
    fixed = bib
    target_fields = fixed.fields('776')
    target_fields.each do |field|
      next unless valid_ind1.include?(field.indicator1) || field.to_s =~ /Online/
      field_index = fixed.fields.index(field)
      if field.to_s =~ /Online version/
        fixed.fields.delete_at(field_index)
      elsif field.indicator1 == ' ' && field.indicator2 == ' '
        fixed.fields[field_index].indicator1 = '0'
        fixed.fields[field_index].indicator2 = '8'
      else
        fixed.fields[field_index].indicator1 = '0'
      end
    end
    fixed
  end
end

def process_880(bib)
  return bib if bib.fields('880').empty?
  rec_fields = bib.fields.map { |field| field.tag }
  f880 = bib.fields('880')
  f880.each do |field|
    field_index = bib.fields.index(field)
    del = false
    f6 = field['6']
    if f6.nil?
      del = true
    else
      f_num = f6.gsub(/^([0-9]{3})\-.*$/, '\1')
      f_index = f6.gsub(/^[0-9]{3}\-([0-9]+).*$/, '\1')
      del = true unless rec_fields.include?(f_num) || f_num[0] == '5'
      del = true if !rec_fields.include?(f_num) && f_num[0] == '5' && f_index != '00'
    end
    bib.fields.delete_at(field_index) if del
  end
  bib
end
