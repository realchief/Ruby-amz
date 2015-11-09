require 'excon'
require 'http-cookie'

module AMZBestSellers
  class Probe

    @@permits = Queue.new

    Thread.new do
      loop do
        @@permits << 1 if @@permits.size < 30
        sleep(2)
      end
    end

    DEFAULT_HEADERS = {
      'Accept'     => 'text/html',
      'User-Agent' => 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.80 Safari/537.36'
    }

    def initialize
      @url     = 'http://www.amazon.com'
      @headers = DEFAULT_HEADERS
      @jar     = HTTP::CookieJar.new(store: :hash)

      @bot = Excon.new(@url,
        middlewares: Excon.defaults[:middlewares] +
                     [Excon::Middleware::RedirectFollower],
        headers:     @headers,
        persistent:  true,
        debug:       false
      )
    end

    def query(category, page)
      @@permits.shift
      res = @bot.get(path: "/s?#{build_query_params(category, page)}")

      @jar.parse(res.headers['Set-Cookie'], @url)
      @headers['Cookie'] = HTTP::Cookie.cookie_value(@jar.cookies)

      res
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
