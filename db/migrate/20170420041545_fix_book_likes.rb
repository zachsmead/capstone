class FixBookLikes < ActiveRecord::Migration[5.0]
  def change
  	remove_column :book_likes, :genre_id, :integer
  	add_column :book_likes, :user_id, :integer
  end
end
