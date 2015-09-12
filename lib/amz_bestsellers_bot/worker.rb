require 'sidekiq'
require 'yaml'
require 'logger'
require 'active_record'
require_relative 'probe'
require_relative 'parser'

LOG = Logger.new(STDOUT)
LOG.datetime_format = "%Y-%m-%d %H:%M:%S"

cfg_dir = File.expand_path('../../../config', __FILE__)
db_cfg  = YAML.load(File.read(File.join(cfg_dir, 'database.yml')))

ActiveRecord::Base.configurations = db_cfg
ActiveRecord::Base.establish_connection(:development)

require_relative 'best_seller'

module AMZBestSellersBot
  class Worker

    include Sidekiq::Worker

    def initialize
      @probe = Probe.new
    end

    # Apparel & Accessories   (1036592)    Not found
    # Arts, Crafts & Sewing   (2617941011) Done
    # Automotive              (15684181)   Done
    # Baby                    (165796011)  Done
    # Beauty                  (3760911)    Done
    # Camera & Photo          (502394)     Done
    # Car Toys                (10963061)   Only 650 items
    # Health & Personal Care  (3760901)    Done
    # Home & Kitchen          (1055398)    Done
    # Industrial & Scientific (16310091)   Done
    # Jewelry                 (3367581)    Not found
    # Kitchen & Dining        (284507)     Done
    # Musical Instruments     (11091801)   Done
    # Office Products         (1064954)    Done
    # Pet Supplies            (2619533011) Done
    # Shoes                   (672123011)  Not found
    # Specialty Stores        (-4505)      Not found
    # Sports & Outdoors       (3375251)    Done
    # Tools & Hardware        (228013)     Done
    # Toys and Games          (165793011)  Done
    #
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
