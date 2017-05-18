class AddCardTitleToBooks < ActiveRecord::Migration[5.0]
  def change
  	add_column :books, :card_title, :string
  end
end
