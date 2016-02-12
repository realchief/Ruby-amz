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

    private

    def initialize_http_session
      @http_bot.get '/Best-Seelers/zgbs'
    end
  end
end
