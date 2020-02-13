require 'mysql2'
module SFXWorldcat
  def unwanted_target_ids
    [
      3780000000001251,
      3810000000000426,
      1000000000000645,
      5280000000000120, 
      5280000000000114,
      5280000000000115,
      5280000000000116,
      5280000000000122,
      5280000000000123,
      5280000000000124,
      5280000000000125,
      5280000000000126,
      5280000000000127,
      5280000000000128,
      5280000000000129,
      5280000000000130,
      5280000000000135,
      5280000000000136,
      5280000000000132,
      5280000000000133,
      5280000000000131
    ]
  end

  def cjkr_languages
    %w[chi kor jpn rus]
  end

  def get_unwanted_objects(client)
    object_ids = Set.new
    client.query(unwanted_object_query).each do |row|
      object_ids << row['object_id']
    end
    client.query(local_skip_object_query).each do |row|
      object_ids << row['object_id']
    end
    object_ids
  end

  def get_current_objects(client)
    object_ids = Set.new
    client.query(object_id_query).each do |row|
      object_ids << row['object_id']
    end
    object_ids
  end

  def get_local_brief_objects(client)
    object_ids = Set.new
    client.query(local_brief_object_query).each do |row|
      object_ids << row['object_id']
    end
    object_ids
  end

  def get_local_objects(client)
    object_ids = Set.new
    client.query(local_object_query).each do |row|
      object_ids << row['object_id']
    end
    object_ids
  end

  def changed_object_title(date, client)
    object_ids = []
    client.query(changed_object_title_query(date)).each do |row|
      object_ids << row['object_id']
    end
    object_ids
  end

  def changed_local_title(date, client)
    object_ids = []
    client.query(changed_local_title_query(date)).each do |row|
      object_ids << row['object_id']
    end
    object_ids
  end

  def changed_publisher(date, client)
    object_ids = []
    client.query(changed_publisher_query(date)).each do |row|
      object_ids << row['object_id']
    end
    object_ids
  end

  def changed_author(date, client)
    object_ids = []
    client.query(changed_author_query(date)).each do |row|
      object_ids << row['object_id']
    end
    object_ids
  end

  def changed_identifier(date, client)
    object_ids = []
    client.query(changed_identifier_query(date)).each do |row|
      object_ids << row['object_id']
    end
    object_ids
  end

  def changed_local_identifier(date, client)
    object_ids = []
    client.query(changed_local_identifier_query(date)).each do |row|
      object_ids << row['object_id']
    end
    object_ids
  end

  def changed_relations(date, client)
    object_ids = []
    client.query(changed_relations_query(date)).each do |row|
      object_ids << row['object_id']
    end
    object_ids
  end

  def get_changed_objects(date, client)
    object_ids = Set.new
    changed_relations(date, client).each do |id|
      object_ids << id
    end
    changed_identifier(date, client).each do |id|
      object_ids << id
    end
    changed_local_identifier(date, client).each do |id|
      object_ids << id
    end
    changed_publisher(date, client).each do |id|
      object_ids << id
    end
    changed_author(date, client).each do |id|
      object_ids << id
    end
    changed_local_title(date, client).each do |id|
      object_ids << id
    end
    changed_object_title(date, client).each do |id|
      object_ids << id
    end
    object_ids
  end

  def get_related_objects(object_id, client)
    objects = []
    client.query(related_object_query(object_id)).each do |row|
      object = {}
      object[:object_id] = row['secondary_object_id']
      object[:relation_type] = row['relation_type']
      object[:language] = row['language']
      objects << object
    end
    objects
  end

  def get_related_title(object_id, language, client)
    titles = get_titles(object_id, language, client)
    return nil if titles.empty?
    main_title = nil
    titles.each do |title|
      next unless title[:type] == 'MAIN'
      main_title = title[:value]
      main_title = main_title[title[:non_filing]..-1] if title[:non_filing]
    end
    main_title
  end

  def get_related_issn(object_id, client)
    identifiers = get_identifiers(object_id, client)
    return nil if identifiers.empty?
    print = nil
    electronic = nil
    identifiers.each do |identifier|
      next unless identifier['type'] == 'ISSN'
      if identifier['sub_type'] == 'PRINT'
        print = identifier['value']
      elsif identifier['sub_type'] == 'ELECTRONIC'
        electronic = identifier['value']
      end
    end
    electronic ? electronic : print
  end

  def get_tag_ind2_from_relation_type(relation_type)
    tag = nil
    ind2 = ' '
    case relation_type
    when 'TRANSLATION_ENTRY'
      tag = '767'
    when 'SUPPLEMENT'
      tag = '770'
    when 'SUPPLEMENT_PARENT'
      tag = '772'
    when 'OTHER_EDITION'
      tag = '775'
    when 'CONTINUES'
      tag = '780'
      ind2 = '0'
    when 'CONTINUES_IN_PART'
      tag = '780'
      ind2 = '1'
    when 'FORMED_BY_THE_UNION_OF'
      tag = '780'
      ind2 = '4'
    when 'ABSORBED'
      tag = '780'
      ind2 = '5'
    when 'ABSORBED_IN_PART'
      tag = '780'
      ind2 = '6'
    when 'CONTINUED_BY'
      tag = '785'
      ind2 = '0'
    when 'CONTINUED_IN_PART_BY'
      tag = '785'
      ind2 = '1'
    when 'ABSORBED_BY'
      tag = '785'
      ind2 = '4'
    when 'ABSORBED_IN_PART_BY'
      tag = '785'
      ind2 = '5'
    when 'SPLIT_INTO'
      tag = '785'
      ind2 = '6'
    when 'MERGED_INTO'
      tag = '785'
      ind2 = '7'
    when 'RELATED'
      tag = '787'
    end
    [tag, ind2]
  end

  def get_identifiers(object_id, client)
    identifiers = []
    client.query(identifier_query(object_id)).each do |row|
      identifiers << row
    end
    identifiers
  end

  def get_local_identifier(object_id, client)
    row = client.query(local_identifier_query(object_id)).first
    return nil unless row
    identifier = row['value']
    identifier.gsub!(/OCLC|oclc/, '')
    identifier
  end

  ### Return array of author hash
  def get_authors(object_id, client)
    authors = []
    query = author_query(object_id)
    client.query(query).each do |row|
      author = {}
      author[:name] = row['full_name']
      author[:format] = row['full_name_format']
      author[:type] = row['type']
      author[:role] = row['author_significance']
      author[:id] = row['author_id']
      authors << author
    end
    authors
  end

  def get_raw_titles(object_id, client)
    titles = []
    query = title_query(object_id)
    client.query(query).each do |row|
      title = {}
      title[:value] = row['local_title'] ? row['local_title'] : row['title_value']
      title[:non_filing] = row['local_non_filing'] ? row['local_non_filing'] : row['non_filing_char']
      title[:type] = row['title_type']
      title[:subtype] = row['title_sub_type']
      title[:language] = row['title_language']
      titles << title
    end
    titles
  end

  def get_raw_publishers(object_id, client)
    publishers = []
    query = publisher_query(object_id)
    client.query(query).each do |row|
      publisher = {}
      publisher[:name] = row['publisher_name_display']
      date = row['date_of_publication'].to_s
      publisher[:date] = date == '0' ? nil : date
      publisher[:place] = row['place_of_publication_display']
      publishers << publisher
    end
    publishers
  end

  def get_language(object_id, client)
    query = language_query(object_id)
    row = client.query(query).first
    row.nil? ? nil : row['language']
  end

  def get_target_name(object_id, client)
    query = target_name_query(object_id)
    row = client.query(query).first
    row.nil? ? nil : row['target_name']
  end
end
