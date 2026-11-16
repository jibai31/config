ActiveRecord::Schema[8.0].define(version: 2026_10_01_000000) do
  enable_extension "pgcrypto"

  create_table "users", id: :uuid do |t|
    t.string "api_token", null: false
    t.timestamps
    t.index ["api_token"], unique: true
  end

  create_table "cards", id: :uuid do |t|
    t.string "name", null: false
    t.timestamps
  end

  create_table "tastings", id: :uuid do |t|
    t.uuid "user_id", null: false
    t.uuid "card_id", null: false
    t.date "tasted_on", null: false
    t.integer "rating"
    t.text "notes"
    t.timestamps
    t.index ["user_id"]
    t.index ["card_id"]
  end

  add_foreign_key "tastings", "users"
  add_foreign_key "tastings", "cards"
end
