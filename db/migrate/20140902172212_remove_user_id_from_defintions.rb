class RemoveUserIdFromDefintions < ActiveRecord::Migration
  def change
    remove_column :definitions, :user_id
  end
end
