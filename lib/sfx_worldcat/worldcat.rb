module SFXWorldcat
  def worldcat_conn
    conn = Faraday.new(url: WORLDCAT_SEARCH_URL) do |faraday|
      faraday.request   :url_encoded
      faraday.response  :logger
      faraday.adapter   Faraday.default_adapter
    end
    conn
  end

  def worldcat_sru(query, num_records = 1)
    record = worldcat_conn.get do |req|
      req.params['query'] = query
      req.params['maximumRecords'] = num_records.to_s
      req.params['servicelevel'] = 'full'
      req.params['sortKeys'] = 'LibraryCount,,0'
      req.params['wskey'] = WORLDCAT_API_KEY
      req.params['frbrGrouping'] = 'off'
    end
    return nil unless record.body =~ /<recordData>/
    parse_record_body(record.body)
  end

  def parse_record_body(body)
    output = body.delete "\n"
    output.gsub!(/^.*<records>(.*)<\/records>.*$/, '\1')
    output.gsub!(/<\/recordData><\/record><record><recordSchema>marcxml<\/recordSchema><recordPacking>xml<\/recordPacking><recordData>/, '')
    output.gsub!(/<record><recordSchema>marcxml<\/recordSchema><recordPacking>xml<\/recordPacking><recordData>/, '')
    output.gsub!(/<\/recordData><\/record>/, '')
    output
  end

  def oclc_no_query(oclc_no)
    "srw.no any \"#{oclc_no}\" and srw.mt any \"cnr\""
  end

  def issn_first_query(issn)
    "srw.in any \"#{issn}\" and srw.pc any \"Y\" and srw.mt all \"com cnr\""
  end

  def issn_second_query(issn)
    "srw.in any \"#{issn}\" and srw.li any \"PUL\" and srw.mt any \"cnr\""
  end

  def issn_third_query(issn)
    "srw.in any \"#{issn}\" and srw.pc any \"Y\" and srw.mt any \"cnr\""
  end

  def issn_fourth_query(issn)
    "srw.in any \"#{issn}\" and srw.mt all \"com cnr\""
  end

  def issn_final_query(issn)
    "srw.in any \"#{issn}\" and srw.mt any \"cnr\""
  end

  def lccn_first_query(lccn)
    "srw.dn any \"#{lccn}\" and srw.pc any \"Y\" and srw.mt all \"com cnr\""
  end

  def lccn_second_query(lccn)
    "srw.dn any \"#{lccn}\" and srw.pc any \"Y\" and srw.li any \"PUL\" and srw.mt any \"cnr\""
  end

  def lccn_third_query(lccn)
    "srw.dn any \"#{lccn}\" and srw.pc any \"Y\" and srw.mt any \"cnr\""
  end
end
