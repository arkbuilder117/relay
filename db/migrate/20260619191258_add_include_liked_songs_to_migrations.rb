class AddIncludeLikedSongsToMigrations < ActiveRecord::Migration[8.0]
  def change
    add_column :migrations, :include_liked_songs, :boolean, null: false, default: false
  end
end
