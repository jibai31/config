class AddSharedToTastings < ActiveRecord::Migration[8.0]
  def change
    add_column :tastings, :shared, :boolean, default: false, null: false
  end
end
