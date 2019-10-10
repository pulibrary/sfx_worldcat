require 'faraday'
require 'date'
require 'marc_cleanup'
require 'yaml'

ROOT_DIR = File.join(File.dirname(__FILE__), '..')

Dir.glob("#{File.dirname(__FILE__)}/sfx_worldcat/*.rb").each do |file|
  name = File.basename(file, '.rb')
  require_relative "sfx_worldcat/#{name}"
end
include SFXWorldcat
