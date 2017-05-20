class AddScrapedContentUrlToBooks < ActiveRecord::Migration[5.0]
  def change
  	add_column :books, :scraped_content_url, :string
  end
end
