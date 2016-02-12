require 'excon'
require 'http-cookie'
require 'nokogiri'
require 'pry'

require 'logger'
require 'active_record'

LOG = Logger.new(STDOUT)
LOG.datetime_format = "%Y-%m-%d %H:%M:%S"

ActiveRecord::Base.raise_in_transactional_callbacks = true
ActiveRecord::Base.logger = LOG
ActiveRecord::Base.establish_connection

require_relative 'lib/amz_bestsellers_bot/models/browse_node'
require_relative 'lib/amz_bestsellers_bot/models/best_seller'

DEFAULT_HEADERS = {}

def setup_bot
  @url     = 'http://www.amazon.com'
  @headers = DEFAULT_HEADERS
  @jar     = HTTP::CookieJar.new(store: :hash)

  @bot = Excon.new(@url,
    middlewares: Excon.defaults[:middlewares] +
                 [Excon::Middleware::RedirectFollower],
    headers:     @headers,
    expects:     200,
    persistent:  true,
    debug:       true
  )
end

categories = [
  'Appliances',           'Arts, Crafts & Sewing',     'Automotive',
  'Baby',                 'Beauty',                    'Books',
  'Camera & Photo',       'Cell Phones & Accessories', 'Clothing',
  'Electronics',          'Grocery & Gourmet Food',    'Health & Personal Care',
  'Home & Kitchen',       'Home Improvement',          'Industrial & Scientific',
  'Jewelry',              'Musical Instruments',       'Office Products',
  'Patio, Lawn & Garden', 'Pet Supplies',              'Shoes',
  'Sports & Outdoors',    'Toys & Games',              'Watches'
]

def get_full_page_via_ajax(uri_path, page_num)
  query = { '_encoding' => 'UTF8', 'pg' => page_num, 'ajax' => 1 }

  res_a = @bot.get(path: uri_path, query: query)
  res_b = @bot.get(path: uri_path, query: query.merge({'isAboveTheFold' => 0}))

  (res_a.body << res_b.body).gsub("\n", ' ').squeeze(' ')
end

setup_bot
res = @bot.get(path: '/Best-Sellers/zgbs')

@jar.parse(res.headers['Set-Cookie'], @url) if res.headers['Set-Cookie']
@headers['Cookie'] = HTTP::Cookie.cookie_value(@jar.cookies)

stale_browse_nodes = BrowseNode
  .where(is_deepest: true)
  .where('crawled_at IS NULL OR crawled_at < ?', Time.now - 60 * 60 * 24 * 14)

stale_browse_nodes.find_each(batch_size: 10) do |browse_node|

  bn_bs_body = 1.upto(5).inject('') do |mem, i|
    mem << get_full_page_via_ajax(browse_node.best_sellers_path, i)
  end

  ASIN_REGEXP = %r(/dp/([A-Z0-9]{10})/)

  @bn_bs_doc = Nokogiri::HTML(bn_bs_body)

  best_sellers = @bn_bs_doc.css('div.zg_itemImmersion').map do |product_node|
    rank = product_node.at('span.zg_rankNumber').text

    if (title_node = product_node.at('div.zg_title'))
      product_uri = URI(title_node.at('> a')['href'].strip)
      slug, asin  = product_uri.path.split('/').values_at(1, 3)

      product_reviews_str = product_node.at('div.zg_reviews').text.squeeze(' ')
      match = product_reviews_str.match(/(\d.\d) out of 5 stars \(([0-9]+)\)/)

      if match
        rating       = match.captures[0].to_f
        review_count = match.captures[1].delete("^0-9").to_i
      else
        rating = review_count = nil
      end
    else
      asin = slug = rating = review_count = nil
    end

    BestSeller.new(
      browse_node_id: browse_node.id,
      rank:           rank.delete("^0-9").to_i,
      asin:           asin,
      slug:           slug,
      rating:         rating,
      review_count:   review_count
    )
  end

  ActiveRecord::Base.transaction do
    BestSeller.where(browse_node_id: browse_node.id).delete_all
    best_sellers.each(&:save!)

    browse_node.update!(crawled_at: Time.now)
  end
end
