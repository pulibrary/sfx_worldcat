require 'faraday'
require 'date'

ROOT_DIR = File.join(File.dirname(__FILE__), '..')

%w[
  worldcat
  sfx_queries
  sfx
  record_process
  record_select
  brief_rec
  get_rec
].each do |f|
  require_relative "sfx_worldcat/#{f}"
end
