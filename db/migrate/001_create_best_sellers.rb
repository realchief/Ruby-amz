class CreateBestSellers < ActiveRecord::Migration

  def change
    create_table :best_sellers do |t|
      t.string   :asin
      t.integer  :category_id, limit: 8
      t.integer  :position,    limit: 2
      t.datetime :created_at
    end
  end

end
