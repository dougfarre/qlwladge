class AddDataMapToSyncOperations < ActiveRecord::Migration
  def change
    add_column :sync_operations, :mapped_data, :text
  end
end
