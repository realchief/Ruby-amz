class CreateBestSellers < ActiveRecord::Migration

  def change
    create_table :best_sellers do |t|
      t.column :browse_node_id, :integer,  limit: 8
      t.column :rank,           :integer,  limit: 2
      t.column :asin,           'CHAR(10)'
      t.column :slug,           :string
      t.column :rating,         :decimal,  precision: 4, scale: 2
      t.column :review_count,   :integer,  limit: 3
      t.column :created_at,     :timestamp
    end
  end
end
