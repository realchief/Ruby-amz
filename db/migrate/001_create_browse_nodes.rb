class CreateBrowseNodes < ActiveRecord::Migration

  def change
    create_table :browse_nodes, id: false do |t|
      t.column :id,                :integer,  limit: 8
      t.column :path,              :string
      t.column :query,             :string
      t.column :is_deepest,        :integer,  limit: 1
      t.column :best_sellers_path, :string
      t.column :updated_at,        :timestamp
      t.column :crawled_at,        :timestamp
    end

    execute 'ALTER TABLE browse_nodes ADD PRIMARY KEY (id)'
  end
end
