class AddSmartViewIdsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :smart_view_ids, :string, array: true, default: []
  end
end
