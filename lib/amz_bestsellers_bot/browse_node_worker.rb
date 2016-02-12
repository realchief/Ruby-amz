require 'sidekiq'
require 'logger'
require 'active_record'
require_relative 'probe'
require_relative 'parser'

LOG = Logger.new(STDOUT)
LOG.datetime_format = "%Y-%m-%d %H:%M:%S"

ActiveRecord::Base.raise_in_transactional_callbacks = true
ActiveRecord::Base.logger = LOG
ActiveRecord::Base.establish_connection

require_relative 'models/browse_node'

module AMZBestSellers
  class BrowseNodeWorker

    include Sidekiq::Worker

    def initialize
      @probe  = Probe.new
      @parser = Parser
    end

    def perform(node_id, node_path, query)
      browse_node = BrowseNode.find_or_initialize_by(id: node_id)

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
  end
end
