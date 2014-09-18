class AddSourceDataBackToSyncOperations < ActiveRecord::Migration
  def change
    add_column :sync_operations, :source_data, :text
  end
end
