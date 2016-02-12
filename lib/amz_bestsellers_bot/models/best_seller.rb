require 'active_record'

class BestSeller < ActiveRecord::Base

  belongs_to :browse_node
end
