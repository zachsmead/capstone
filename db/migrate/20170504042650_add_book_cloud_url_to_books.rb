class AddBookCloudUrlToBooks < ActiveRecord::Migration[5.0]
  def change
  	add_column :books, :book_cloud_url, :string
  end
end
