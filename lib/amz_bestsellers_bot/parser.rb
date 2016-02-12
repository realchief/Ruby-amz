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
  end
end
