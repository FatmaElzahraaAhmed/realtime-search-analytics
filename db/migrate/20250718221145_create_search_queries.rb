class CreateSearchQueries < ActiveRecord::Migration[7.1]
  def change
    create_table :search_queries do |t|
      t.string :term
      t.string :ip_address
      t.integer :search_count

      t.timestamps
    end
  end
end
