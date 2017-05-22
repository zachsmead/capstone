class AddTwitterAndRedditUsernameToBooks < ActiveRecord::Migration[5.0]
  def change
  	add_column :books, :reddit_username, :string
  	add_column :books, :twitter_username, :string
  end
end
