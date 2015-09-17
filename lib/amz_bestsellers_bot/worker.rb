require 'sidekiq'
require 'logger'
require 'active_record'
require_relative 'probe'
require_relative 'parser'

LOG = Logger.new(STDOUT)
LOG.datetime_format = "%Y-%m-%d %H:%M:%S"

ActiveRecord::Base.raise_in_transactional_callbacks = true
ActiveRecord::Base.establish_connection

require_relative 'best_seller'

module AMZBestSellers
  class Worker

    include Sidekiq::Worker

    def initialize
      @probe = Probe.new
    end

    def perform(category, max_results)
      page = 0
      collected_results = []

      while collected_results.size < max_results.to_i do
        res = @probe.query(category, page += 1)
        LOG.info "Fetched page #{page}"

        captcha_page = !!(res.body =~ /Type the characters you see in this image/i)
        LOG.info "Fetched captcha page: #{captcha_page}"

        results = Parser.parse_asins(res.body)
        LOG.info "Scraped #{results.size} products"

        collected_results = (collected_results | results)
        LOG.info "Collected results: #{collected_results.size}"
      end

      collected_results.each_with_index do |asin, pos|
        bs = BestSeller.find_or_initialize_by(asin: asin, category_id: category)
        bs.position   = pos + 1
        bs.updated_at = DateTime.now
        bs.save
      end
    end
  end
end
