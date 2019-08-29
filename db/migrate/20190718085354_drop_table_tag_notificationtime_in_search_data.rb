class DropTableTagNotificationtimeInSearchData < ActiveRecord::Migration[5.2]
  def change
    remove_column :search_data , :tag , :string
    remove_column :search_data , :date_range , :string 
    remove_column :search_data , :notification_time, :string 
  end
end
