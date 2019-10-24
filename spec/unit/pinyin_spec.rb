require 'spec_helper'
require 'sfx_worldcat'
require 'byebug'

describe 'SFXWorldcat::string_to_pinyin' do
  let(:dict) { SFXWorldcat::chi_dict }
  let(:chinese_tag) { '880' }
  let(:linking_subf) { '6' }
  
  context "first pinyin_sample" do
    let(:marc_record) do
      reader = MARC::Reader.new('spec/fixtures/pinyin_number_sample.mrc')
      reader.first
    end

    it 'converts pinyin: changing Chinese numbers into Arabic numerals' do
      tag = '264'
      subfield_code = 'b'

      # save off chinese
      chinese_str = extract_chinese_from_field(tag, subfield_code) 
      
      # save off the pinyin
      pinyin_str = marc_record[tag][subfield_code]
      
      # run the chinese through string_to_pinyin
      output = SFXWorldcat::string_to_pinyin(chinese_str, 
                                            tag, {ind1: '0' , ind2: '0' }, 
                                            subfield_code,  dict)

      expect(output).to eq(pinyin_str)
    end

    it 'converts pinyin without numbers in record' do
      tag = '245'
      subfield_code = 'a'

      # save off chinese
      chinese_str = extract_chinese_from_field(tag, subfield_code)
      
      # save off the pinyin
      pinyin_str = marc_record[tag][subfield_code]
      
      # run the chinese through string_to_pinyin
      output = SFXWorldcat::string_to_pinyin(chinese_str, 
                                            tag, {ind1: '0' , ind2: '0' }, 
                                            subfield_code,  dict)

      expect(output).to eq(pinyin_str)
    end
  end
  def extract_chinese_from_field(tag, subfield_code)
    chinese_field = marc_record.fields.select { |field| field.tag == chinese_tag && field[linking_subf] =~ /^#{tag}/ }.first
    chinese_field[subfield_code]
  end
end
