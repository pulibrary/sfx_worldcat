require 'spec_helper'
require 'sfx_worldcat'
require 'byebug'

describe 'SFXWorldcat::string_to_pinyin' do
  let(:dict) { SFXWorldcat::chi_dict }

  
  context "first pinyin_sample" do
    let(:marc_record) do
      reader = MARC::Reader.new('spec/fixtures/pinyin_sample.mrc')
      reader.first
    end

    it "converts pinyin" do
      tag = '245'
      subfield_code = 'p'

      # save off chinese
      chinese_str = marc_record['880'][subfield_code]
      
      # save off the pinyin
      pinyin_str = marc_record[tag][subfield_code]
      
      # run the chinese through string_to_pinyin
      output = SFXWorldcat::string_to_pinyin(chinese_str, 
                                            tag, {ind1: '0' , ind2: '0' }, 
                                            subfield_code,  dict)

      expect(output).to eq(pinyin_str)
    end

    it "converts pinyin" do
      tag = '245'
      subfield_code = 'a'

      # save off chinese
      chinese_str = marc_record['880'][subfield_code]
      
      # save off the pinyin
      pinyin_str = marc_record[tag][subfield_code]
      
      # run the chinese through string_to_pinyin
      output = SFXWorldcat::string_to_pinyin(chinese_str, 
                                            tag, {ind1: '0' , ind2: '0' }, 
                                            subfield_code,  dict)

      expect(output).to eq(pinyin_str)
    end
  end
end
