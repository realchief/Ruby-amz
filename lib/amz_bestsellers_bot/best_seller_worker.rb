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
require_relative 'models/best_seller'

module AMZBestSellers
  class BestSellerWorker

    include Sidekiq::Worker

    @@probe  = Probe.new
    @@parser = Parser

    def perform(node_id)
      browse_node = BrowseNode.find_by(id: node_id)

      bn_bs_body = @@probe.fetch_all_best_sellers_via_ajax(
        browse_node.best_sellers_path
      )

      ActiveRecord::Base.transaction do
        BestSeller.where(browse_node_id: browse_node.id).delete_all

        @@parser.parse_best_sellers(bn_bs_body).each do |attrs|
          BestSeller.create!(attrs.merge(browse_node_id: browse_node.id))
        end

        browse_node.update!(crawled_at: Time.now)
      end
    end
  end
end
