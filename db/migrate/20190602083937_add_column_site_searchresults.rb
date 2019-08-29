class AddColumnSiteSearchresults < ActiveRecord::Migration[5.2]
  def change
    add_column :search_results, :site, :string
  end
end
