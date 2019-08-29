class AddColumunTerm < ActiveRecord::Migration[5.2]
  def change
    add_column :search_results, :term, :string
  end
end
