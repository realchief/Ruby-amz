require 'pry'
require 'logger'
require 'active_record'

LOG = Logger.new(STDOUT)
LOG.datetime_format = "%Y-%m-%d %H:%M:%S"

ActiveRecord::Base.raise_in_transactional_callbacks = true
ActiveRecord::Base.logger = LOG
ActiveRecord::Base.establish_connection

require_relative 'lib/amz_bestsellers_bot/models/browse_node'
require_relative 'lib/amz_bestsellers_bot/probe'
require_relative 'lib/amz_bestsellers_bot/parser'

STALE_BEFORE = Time.now - (60 * 60 * 24 * 30)

probe  = AMZBestSellers::Probe.new
parser = AMZBestSellers::Parser

browse_nodes = File.readlines(ARGV.shift, encoding: 'utf-8').map(&:chomp)

browse_nodes.each do |row|
  node_id, node_path, query = row.split("\t", -1)

  browse_node = BrowseNode.find_or_initialize_by(id: node_id)
  next if browse_node.updated_at and browse_node.updated_at > STALE_BEFORE

  res = probe.fetch_browse_node_details(browse_node.id)
  is_deepest = parser.browse_node_is_deepest?(res)

  res = probe.fetch_browse_node_best_sellers_home(browse_node.id)
  best_sellers_path = parser.parse_browse_node_best_sellers_path(res)

  browse_node.update!(
    path:              node_path,
    query:             query,
    is_deepest:        is_deepest,
    best_sellers_path: best_sellers_path,
    updated_at:        Time.now
  )
end
