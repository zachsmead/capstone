class AddAnalysisUrlToBooks < ActiveRecord::Migration[5.0]
  def change
  	add_column :books, :analysis_url, :string
  end
end
