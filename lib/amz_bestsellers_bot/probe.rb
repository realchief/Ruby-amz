require 'excon'

module AMZBestSellers
  class Probe

    def initialize
      @bot = Excon.new('http://www.amazon.com',
        middlewares: Excon.defaults[:middlewares] +
                     [Excon::Middleware::RedirectFollower],
        persistent:  true,
        debug:       false
      )
    end

    def query(category, page)
      @bot.get(path: "/s?#{build_query_params(category, page)}")
    end

    private

    def build_query_params(category, page)
      [
        "fields-keywords=-asdfqaz",
        "node=#{category}",
        "page=#{page}",
        "sort=salesrank"
      ] * '&'
    end
  end
end
