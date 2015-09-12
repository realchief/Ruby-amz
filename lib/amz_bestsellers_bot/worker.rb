require 'sidekiq'
require 'yaml'
require 'logger'
require 'active_record'
require 'pry'
require_relative 'probe'

LOG = Logger.new(STDOUT)
LOG.datetime_format = "%Y-%m-%d %H:%M:%S"

cfg_dir = File.expand_path('../../../config', __FILE__)
db_cfg  = YAML.load(File.read(File.join(cfg_dir, 'database.yml')))

ActiveRecord::Base.configurations = db_cfg
ActiveRecord::Base.establish_connection(:development)

require_relative 'best_seller'

class Worker

  include Sidekiq::Worker

  def initialize
    @probe = Probe.new
  end

  def perform(category, max_results)
    page = 0
    collected_results = []

    while collected_results.size < max_results.to_i do
      res = @probe.query(category, page)
      LOG.info "Fetched page #{page}"

      captcha_page = !!(res.body =~ /Type the characters you see in this image/i)
      LOG.info "Fetched captcha page: #{captcha_page}"

      results = res.body.scan(/<li id="result_[0-9]{1,}" data-asin="([A-Z0-9]{10})"/).flatten
      LOG.info "Scraped #{results.size} products"

      collected_results = (collected_results | results)
      LOG.info "Collected results: #{collected_results.size}"
    end

    collected_results.each_with_index do |asin, pos|
      BestSeller.create(asin: asin, position: pos + 1, category_id: category)
    end
  end
end
