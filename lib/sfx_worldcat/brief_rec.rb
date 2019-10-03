module SFXWorldcat
  def process_no_match(object_id, client, record_date, dict)
    language = get_language(object_id, client)
    publishers = get_publishers(object_id, language, client)
    titles = get_titles(object_id, language, client)
    authors = get_authors(object_id, client)
    related_objects = process_related_objects(object_id, client)
    identifiers = get_identifiers(object_id, client)
    ## Identifier pre-processing
    lccns = []
    print_issn = nil
    elec_issn = nil
    unless identifiers.empty?
      identifiers.each do |identifier|
        next unless %w[ISSN LCCN].include? identifier['type']
        if identifier['type'] == 'ISSN'
          case identifier['sub_type']
          when 'PRINT'
            print_issn = MARC::Subfield.new('y', identifier['value'])
          when 'ELECTRONIC'
            elec_issn = MARC::Subfield.new('a', identifier['value'])
          end
        else
          lccns << identifier['value']
        end
      end
    end

    ## Author pre-processing
    main_author = nil
    add_authors = []
    unless authors.empty?
      authors.each do |author|
        if author[:role] == 'MAIN'
          main_author = author
        elsif author[:role] == 'ADDITIONAL'
          add_authors << author
        end
      end
    end
    main_author_field = process_main_author(main_author)

    ## Title pre-processing
    main_title = nil
    alt_titles = []
    titles.each do |title|
      case title[:type]
      when 'MAIN'
        main_title = title
      when 'TRANSLATION'
        alt_titles << title
      when 'ABBREVIATION'
        alt_titles << title
      when 'ROMANIZATION'
        alt_titles << title
      when 'WRITING_SYSTEM'
        alt_titles << title
      when 'ALTERNATIVE'
        alt_titles << title
      when 'UNIFORM'
        alt_titles << title
      end
    end
    main_title ||= alt_titles.shift
    main_title_field = process_main_title(main_title)
    ## Publisher pre-processing
    pub_field = process_publishers(publishers)
    ## Fixed fields
    record = MARC::Record.new
    record.leader[0..4] = '00000'
    record.leader[5..7] = 'nas'
    record.leader[9] = 'a'
    record.leader[17] = '5'
    record.append(MARC::ControlField.new('001', object_id))
    record.append(MARC::ControlField.new('003', 'SFX'))
    field008_value = "#{record_date}|||||||||xx || ||o||||||   ||#{language}||"
    record.append(MARC::ControlField.new('008', field008_value))
    ## 010-099
    unless lccns.empty?
      record.append(MARC::DataField.new('010', ' ', ' ', ['a', lccns.first]))
    end
    if print_issn || elec_issn
      issn_field = MARC::DataField.new('022', ' ', ' ')
      issn_field.append(elec_issn) if elec_issn
      issn_field.append(print_issn) if print_issn
      record.append(issn_field)
    end
    record.append(MARC::DataField.new('090', ' ', ' ', ['a', 'Electronic Resource']))
    ## Author area
    if main_author_field
      record.append(main_author_field)
      main_title_field.indicator1 = '1'
    end

    ## Title area
    record.append(main_title_field)
    unless alt_titles.empty?
      alt_titles.each do |alt_title|
        next if alt_title[:value] == main_title[:value]
        alt_title_field = process_alt_title(alt_title)
        record.append(alt_title_field)
      end
    end

    ## Publisher area
    record.append(pub_field) unless pub_field.nil?

    ## Related objects
    unless related_objects.empty?
      related_objects.each do |field|
        record.append(field)
      end
    end
    record = process_bib_base(record, object_id, dict)
    record
  end
end
