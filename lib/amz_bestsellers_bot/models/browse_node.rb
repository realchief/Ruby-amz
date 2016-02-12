require 'active_record'

class BrowseNode < ActiveRecord::Base

  has_many :best_sellers
end
