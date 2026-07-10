class CreateSpotifyAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :spotify_accounts do |t|
      t.references :user,             null: false, foreign_key: true, index: { unique: true }
      t.string     :spotify_id,       null: false
      t.string     :display_name
      t.string     :access_token,     null: false
      t.string     :refresh_token,    null: false
      t.datetime   :token_expires_at, null: false
      t.timestamps
    end
    add_index :spotify_accounts, :spotify_id, unique: true
  end
end
