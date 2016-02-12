require 'addressable'
require 'nokogiri'

module AMZBestSellers
  class Parser

    def self.browse_node_is_deepest?(res)
      root_node  = res['BrowseNodeLookupResponse']['BrowseNodes']['BrowseNode']
      is_deepest = root_node['Children'] ? 0 : 1 if root_node

      is_deepest || nil
    end

    def self.parse_browse_node_best_sellers_path(res)
      if res.success?
        res_body = res.body.gsub("\n", ' ').squeeze(' ')
        doc      = Nokogiri::HTML(res_body)

        Addressable::URI.parse(doc.at("link[rel='canonical']")['href']).path
      else
        nil
      end
    end

    def self.parse_best_sellers(html)
      doc = Nokogiri::HTML::DocumentFragment.parse(html)

      doc.css('div.zg_itemImmersion').map do |node|
        best_seller = {}

        rank = node.at('span.zg_rankNumber').text
        best_seller[:rank] = rank.delete("^0-9").to_i

        if (title_node = node.at('div.zg_title'))
          product_uri = URI(title_node.at('> a')['href'].strip)
          slug, asin  = product_uri.path.split('/').values_at(1, 3)
          best_seller[:slug] = slug
          best_seller[:asin] = asin

          reviews_str = node.at('div.zg_reviews').text.squeeze(' ')
          match = reviews_str.match(/(\d.\d) out of 5 stars \(([0-9]+)\)/)

          if match
            best_seller[:rating]       = match.captures[0].to_f
            best_seller[:review_count] = match.captures[1].delete("^0-9").to_i
          end
        end

        best_seller
      end
    end
  end
end
