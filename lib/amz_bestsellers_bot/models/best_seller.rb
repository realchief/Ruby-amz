require 'active_record'
require 'paper_trail'

class BestSeller < ActiveRecord::Base

  has_paper_trail ignore: [:updated_at]

end
