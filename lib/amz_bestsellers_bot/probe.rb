require 'excon'
require 'http-cookie'

module AMZBestSellers
  class Probe

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
      res = @bot.get(path: "/s?#{build_query_params(category, page)}")

      @jar.parse(res.headers['Set-Cookie'], @url) if res.headers['Set-Cookie']
      @headers['Cookie'] = HTTP::Cookie.cookie_value(@jar.cookies)

      res.body = res.body.gsub("\n", ' ')
      res.body = res.body.squeeze(' ')

      if res.body =~ /we just need to make sure you're not a robot/i
        raise RuntimeError, 'Captcha detected'
      end

      res
    rescue RuntimeError
      sleep(2)
      retry
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
