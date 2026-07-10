class CreateAppleMusicAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :apple_music_accounts do |t|
      t.references :user,             null: false, foreign_key: true, index: { unique: true }
      t.string     :music_user_token, null: false
      t.string     :storefront,       null: false, default: "us"
      t.timestamps
    end
  end
end
