require 'yaml'
require 'logger'
require 'excon'
require 'active_record'
require 'pry'

LOG = Logger.new(STDOUT)
LOG.datetime_format = "%Y-%m-%d %H:%M:%S"

cfg_dir = File.expand_path('../config', __FILE__)
db_cfg  = YAML.load(File.read(File.join(cfg_dir, 'database.yml')))

ActiveRecord::Base.configurations = db_cfg
ActiveRecord::Base.establish_connection(:development)

class BestSeller < ActiveRecord::Base
end

# http://www.amazon.com/s?field-keywords=-asdfqaz&node=3760911&page=[001-150]&sort=salesrank
#
# 48 results per page
#
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

category, max_results = ARGV
conn = Excon.new('http://www.amazon.com',
 middlewares: Excon.defaults[:middlewares] + [Excon::Middleware::RedirectFollower],
 persistent:  true, debug: false
)

page = 0
collected_results = []

while collected_results.size < max_results.to_i do
  res = conn.get(path: "/s?field-keywords=-asdfqaz&node=#{category}&page=#{page += 1}&sort=salesrank")
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
