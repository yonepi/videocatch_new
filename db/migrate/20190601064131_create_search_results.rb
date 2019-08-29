class CreateSearchResults < ActiveRecord::Migration[5.2]
  def change
    create_table :search_results do |t|
      t.string :user_id
      t.string :keyword
      t.datetime :get_time
      t.string :thumbnail_url
      t.string :title
      t.string :video_url
      t.string :channel
      t.string :channel_url
      t.string :duration
      t.datetime :published_time

      t.timestamps
    end
  end
end
