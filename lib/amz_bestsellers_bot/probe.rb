require 'vacuum'
require 'faraday'
require 'faraday-cookie_jar'

module AMZBestSellers
  class Probe

    @@permits = Queue.new

    Thread.new do
      loop do
        @@permits << true if @@permits.empty?
        sleep(1)
      end
    end

    def initialize
      @vacuum = Vacuum.new
      @vacuum.configure(associate_tag: ENV['AMZ_ASSOCIATE_TAG'])

      @http_bot = Faraday.new(url: 'http://www.amazon.com') do |faraday|
        faraday.use      :cookie_jar
        faraday.response :logger                  # log requests to STDOUT
        faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
      end

      initialize_http_session
    end

    def fetch_browse_node_details(node_id)
      @@permits.shift

      @vacuum.browse_node_lookup(
        persistent: true,
        query:      { 'BrowseNodeId' => node_id }
      ).to_h
    end

    def fetch_browse_node_best_sellers_home(node_id)
      @http_bot.get "/Best-Sellers/zgbs/apparel/#{node_id}"
    end

    def fetch_all_best_sellers_via_ajax(uri_path)
      1.upto(5).inject('') do |mem, pg|
        query_above_fold = { _encoding: 'UTF8', pg: pg, ajax: 1 }
        query_below_fold = query_above_fold.merge(isAboveTheFold: 0)

        res_above_fold = @http_bot.get(uri_path, query_above_fold)
        res_below_fold = @http_bot.get(uri_path, query_below_fold)

        res_body  = (res_above_fold.body << res_below_fold.body)
        mem      << res_body.gsub("\n", ' ').squeeze(' ')

        doc = Nokogiri::HTML::DocumentFragment.parse(res_body)
        break mem if doc.css('div.zg_itemImmersion').size < 20

        mem
      end
    end

    private

    def initialize_http_session
      @http_bot.get '/Best-Seelers/zgbs'
    end
  end
end
