class CreateSearchData < ActiveRecord::Migration[5.2]
  def change
    create_table :search_data do |t|
      t.string :keyword
      t.string :tag
      t.string :date_range
      t.integer :user_id
      t.string :notification_time

      t.timestamps
    end
  end
end
