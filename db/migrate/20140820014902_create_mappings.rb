class CreateMappings < ActiveRecord::Migration
  def change
    create_table :mappings do |t|
      t.integer :definition_id
      t.string :source_header
      t.integer :destination_field_id

      t.timestamps
    end
  end
end
