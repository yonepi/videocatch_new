class AddColumunOnesignalIdToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :onesignal_id, :string
  end
end
