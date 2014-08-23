class CreateSyncOperations < ActiveRecord::Migration
  def change
    create_table :sync_operations do |t|
      t.integer :definition_id
      t.string :name
      t.string :assigned_service_id
      t.text :source_data
      t.text :response
      t.string :rejects_uri

      t.timestamps
    end
  end
end
