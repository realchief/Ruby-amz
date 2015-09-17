module AMZBestSellers
  class Parser

    def self.parse_asins(html)
      regex = /<li id="result_[0-9]{1,}" data-asin="([A-Z0-9]{10})"/
      html.scan(regex).flatten
    end
  end
end
