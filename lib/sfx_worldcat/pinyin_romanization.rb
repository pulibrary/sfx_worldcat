require_relative './../sfx_worldcat'
module SFXWorldcat
  ### fields to process
  def default_romanization_fields
    ('100'..'499').to_a +
    ('500'..'519').to_a +
    %w[521 522 524 525 526] +
    ('530'..'569').to_a +
    ('600'..'899').to_a
  end

  ### All Unicode blocks for CJK characters
  def chi_pattern
    '[\p{InCJKCompatibility}\p{InCJKUnifiedIdeographsExtensionA}\p{InCJKUnifiedIdeographs}\p{InCJKCompatibilityIdeographs}]'
  end

  ### Latin characters
  def alphanum_pattern
    '[A-Za-z0-9\p{N}\p{M}]'
  end

  ### Pattern for identifying relevant tokens for processing numbers
  def num_token_regex
    /^([A-Za-z]+)#([0-9]*)$/
  end

  ### Loading the character to pinyin hash
  def chi_dict
    YAML.load(File.read("./dict3.yaml"))
  end

  ### Maximum number of characters in the dictionary keys
  def max_char_length(dict)
    dict.keys.max { |a,b| a.length <=> b.length }.size
  end

  ### Substitute groups of Chinese characters with their pinyin equivalent
  def dict_substitute(string, dict)
    string_len = string.size
    vals_to_search = []
    max_char_length(dict).downto(1) do |key_length|
      next if key_length > string_len
      0.upto(string_len - key_length) do |string_byte|
        section = string[string_byte, key_length]
        vals_to_search << section
      end
    end
    vals_to_search.each do |val|
      string.gsub!(/#{val}/, "#{dict[val]} ") if dict[val]
    end
    string
  end

  ### Provide subfield value, field tag, field indicators, and subfield code;
  #     return a fully processed string
  def string_to_pinyin(string, tag, indicators, subf_code, dict)
    new_string = string.dup
    new_string = process_spacing(new_string)
    new_string = dict_substitute(new_string, dict)
    new_string = process_numbers(new_string, tag, subf_code)
    new_string = process_capitalization(new_string, tag, indicators, subf_code)
    new_string.gsub!(/\uff0c/, ',')
    new_string.gsub!(/\p{Z}/, ' ')
    new_string.gsub!(/\s{2, }/, ' ')
    new_string.strip
  end

  ### Identify name strings for further processing
  def is_name?(tag, indicators, subf_code)
    return true if subf_code == 'r'
    tag =~ /^[1678]00/ && indicators[:ind1] == '1' && subf_code == 'a'
  end

  ### Spacing tweaks performed before the dictionary conversion
  def process_spacing(string)
    string.gsub!(/(#{chi_pattern})[\uff0d](#{chi_pattern})/, '\1--\2')
    string.gsub!(/(#{chi_pattern})(#{alphanum_pattern})/, '\1 \2')
    string.gsub!(/(#{alphanum_pattern})(#{chi_pattern})/, '\1 \2')
    string.gsub!(/([,.-])(#{chi_pattern})/, '\1 \2')
    string.gsub!(/([\]\)])(#{chi_pattern})/, '\1 \2')
    string.gsub!(/(#{chi_pattern})([\[\(\]])/, '\1 \2')
    string.gsub!(/([\/:;])(#{chi_pattern})/, '\1 \2')
    string.gsub!(/(#{chi_pattern})([\/:;])/, '\1 \2')
    string.gsub!(/([\)])([\(])/, '\1 \2')
    string
  end

  ### Convert fullwidth and halfwidth characters to their simpler forms
  def normalize_punctuation(string, tag)
    output = ''
    string.chars.each do |val|
      if val =~ /[\uff01-\uffee]/
        output << val.unicode_normalize(:nfkc)
      else
        output << val
      end
    end
    output.gsub!(/[\u3008-\u300b\u301d\u301e]/, '"')
    output.gsub!(/\u3001/, ',')
    output.gsub!(/\p{Separator}/, ' ')
    output.gsub!(/\s+(\))/, '\1')
    output.gsub!(/\s*(\u2022)s*/, '\1')
    output.gsub!(/\s+([,\.])/, '\1')
    output.gsub!(/([^\s])(\;)/, '\1 \2') if %w[245 260 264 300].include?(tag)
    output.gsub!(/(\()\s+/, '\1')
    output.gsub!(/(\;)([^\s])/, '\1 \2')
    output.gsub!(/([\):\.\,\;])([^\s])/, '\1 \2')
    output.gsub!(/([a-z0-9]{2})\s+([\'\"])/, '\1\2')
    output.gsub!(/(\")\s*([^\"]+)\s*(\")/, '\1\2\3')
    output.gsub!(/(\")\s*([^\"]+)\s*(\")([^\s])/, '\1\2\3 \4')
    output.gsub!(/\s*\|\s*/, '|')
    output
  end

  ### Capitialization and punctuation tweaks post-conversion
  def process_capitalization(string, tag, indicators, subf_code)
    string = normalize_punctuation(string, tag)
    string.gsub!(/([;\(]\s*)([a-z])/) { |m| "#{$1}#{$2.upcase}" }
    string.gsub!(/(\u201c)([^\u201c\u201d]+)(\u201d)/) { |m| " #{$1}#{$2[0].upcase}#{$2[1..-1]}#{$3} " }
    string.gsub!(/([\'\u2018])([^\'\u2018\u2019]+)([\'\u2019])/) { |m| " #{$1}#{$2[0].upcase}#{$2[1..-1]}#{$3} " }
    if is_name?(tag, indicators, subf_code)
      comma = subf_code == 'r' ? ',' : ''
      apos = ''
      m = /^(\([^\)]*\) ?)?(\S+)\s+(\S+)\s*(.*)$/.match(new_string)
      if m
        apos = "'" if m[4].size > 0 && m[4] =~ /^[aeiou]/
        string = m[1] + m[2][0].upcase + m[2][1..-1] + comma + ' ' +
          m[3][0].upcase + m[3][1..-1] + apos + m[4]
      end
    end
    string[0] = string[0].upcase
    string.gsub!(/\s\s+/, ' ')
    string
  end

  def force_num_version(tag, subf_code)
    %w[245 830].include?(tag) && subf_code == 'n'
  end

  ### Handle potential numbers in the string
  def process_numbers(string, tag, subf_code)
    return string unless string =~ /\#/
    use_num_version = false
    use_num_version = true if force_num_version(tag, subf_code)
    output_string = ''
    tokens = string.split(/([^\P{P}#])|(\s)/)
    token_count = tokens.size
    i = 0
    while i < token_count
      toki = tokens[i]
      if toki =~ num_token_regex
        num_version = ''
        text_version = ''
        i.upto(token_count - 1).each do |j|
          tokj = tokens[j]
          if (j % 2 == 0 && tokj =~ num_token_regex).nil? || j == token_count - 1
            if tokj =~ num_token_regex
              m = num_token_regex.match(tokj)
              text_version << m[1]
              if m[2] == ''
                num_version << m[1] + ' '
              else
                num_version << m[2] + ' '
              end
            elsif j == token_count - 1
              text_version << tokj + ' '
              num_version << tokj + ' '
            end
            if num_version =~ /^di [0-9]|[0-9] [0-9] [0-9] [0-9]|[0-9]+ nian [0-9]+ yue|[0-9]+ yue [0-9]+ ri/ || use_num_version
              use_num_version = true
              while num_version =~ /[0-9] 10+|[1-9]0+ [1-9]/
                m1 = /([0-9]) (10+)/.match(num_version)
                if m1
                  sum = m1[1].to_i * m1[2].to_i
                  num_version.gsub!(m1[0], sum.to_s)
                else
                  m2 = /([0-9]+) ([1-9]0*)/.match(num_version)
                  if m2
                    sumb = m2[1].to_i + m2[2].to_i
                    num_version.gsub!(m2[0], sumb.to_s)
                  end
                end
              end
              num_version.gsub!(/([0-9]) ([0-9]) ([0-9]) ([0-9])/, '\1\2\3\4')
              if use_num_version
                while num_version =~ /[0-9] [0-9]/
                  num_version.gsub!(/([0-9]) ([0-9])/, '\1\2')
                end
              end
            end
            num_version.strip!
            text_version.strip!
            if use_num_version
              output_string << num_version + ' '
            else
              output_string << text_version + ' '
            end
            i = j
            break
          end
          if j % 2 == 0
            m3 = num_token_regex.match(tokj)
            text_version << m3[1] + ' '
            if m3[2] == ''
              num_version << m3[1] + ' '
            else
              num_version << m3[2] + ' '
            end
          else
            text_version << tokj.strip
            num_version << tokj.strip
          end
        end
      elsif toki.size > 0
        output_string << toki
        i += 1
      else
        i += 1
      end
    end
    output_string
  end

  ### If there are Chinese characters in non-880 fields with corresponding 880s, swap those fields
  def swap_parallel_fields(record)
    orig_fields = record.fields.select { |field| field.class == MARC::DataField && field['6'] && field['6'] =~ /^880\-/}
    parallel_fields = record.fields.select { |field| field.tag == '880' && field['6'] }
    return record if orig_fields.empty? || parallel_fields.empty?
    orig_tags = orig_fields.map { |field| field.tag + '-' + field['6'].gsub(/^[0-9]+\-([0-9]+).*$/, '\1') }.sort_by { |val| val.gsub(/^[^\-]+\-([0-9]+)$/, '\1') }
    parallel_tags = parallel_fields.map { |field| field['6'].gsub(/^(.*)\/.*$/, '\1') }.sort_by { |val| val.gsub(/^[^\-]+\-([0-9]+)$/, '\1') }
    return record if orig_tags != parallel_tags
    orig_fields.each do |field|
      next unless field.to_s =~ /#{chi_pattern}/
      seqnum = field['6'].gsub(/^.*\-([0-9]+).*$/, '\1')
      corresponding = parallel_fields.select { |f| f['6'] =~ /#{field.tag}\-#{seqnum}/ }.first
      lang_info = corresponding['6'].gsub(/^[^$]+(\/\$.*)$/, '\1')
      old_index = record.fields.index(field)
      new_index = record.fields.index(corresponding)
      new_orig = MARC::DataField.new(field.tag, field.indicator1, field.indicator2, MARC::Subfield.new('6', field['6']))
      new_parallel = MARC::DataField.new('880', field.indicator1, field.indicator2, MARC::Subfield.new('6', field.tag + '-' + seqnum + lang_info))
      field.subfields.each do |subfield|
        next if subfield.code == '6'
        new_parallel.subfields << subfield
      end
      corresponding.subfields.each do |subfield|
        next if subfield.code == '6'
        new_orig.subfields << subfield
      end
      record.fields[old_index] = new_orig
      record.fields[new_index] = new_parallel
    end
    record
  end

  ### Return new 880 field with original field text and
  ###   replacement field with pinyin
  def pinyin_unpaired_field(field, seqnum, dict)
    seq_str = seqnum.to_s.rjust(2, '0')
    rep_subf6 = MARC::Subfield.new('6', '880' + '-' + seq_str)
    par_subf6 = MARC::Subfield.new('6', field.tag + '-' + seq_str)
    rep_field = MARC::DataField.new(field.tag, field.indicator1, field.indicator2, rep_subf6)
    par_field = MARC::DataField.new('880', field.indicator1, field.indicator2, par_subf6)
    indicators = { ind1: field.indicator1, ind2: field.indicator2 }
    field.subfields.each do |subfield|
      next if subfield.code == '6'
      if subfield.value =~ /#{chi_pattern}/
        par_field.subfields << subfield
        new_value = subfield.value.dup
        new_value = string_to_pinyin(new_value, field.tag, indicators, subfield.code, dict)
        new_value.gsub!(/\s+([\,])\s*/, '\1 ')
        rep_field.subfields << MARC::Subfield.new(subfield.code, new_value)
      else
        par_field.subfields << subfield
        rep_field.subfields << subfield
      end
    end
    { romanized: rep_field, original: par_field }
  end

  def process_chinese_record(record, dict)
    return record unless record['008'] && record['008'].value[35..37] == 'chi'
    return record unless record.to_s =~ /\/\$1/ || record.to_s =~ /#{chi_pattern}/
    unconverted_fields = record.fields.select { |field| default_romanization_fields.include?(field.tag) && field.to_s =~ /#{chi_pattern}/ }
    record = swap_parallel_fields(record) if unconverted_fields.size
    seqnum = 1
    unconverted_fields.each do |field|
      field_index = record.fields.index(field)
      if field['6'].nil?
        new_fields = pinyin_unpaired_field(field, seqnum, dict)
        seqnum += 1
        record.fields[field_index] = new_fields[:romanized]
        record.fields << new_fields[:original]
      end
    end
    record
  end
end
