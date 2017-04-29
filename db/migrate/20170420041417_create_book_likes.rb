class CreateBookLikes < ActiveRecord::Migration[5.0]
  def change
    create_table :book_likes do |t|
      t.integer :book_id
      t.integer :genre_id

      t.timestamps
    end
  end
end
