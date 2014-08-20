class CreateFields < ActiveRecord::Migration
  def change
    create_table :fields do |t|
      t.integer :definition_id
      t.string :name
      t.string :display_name
      t.string :description
      t.string :data_type
      t.string :statement
      t.string :uri
      t.boolean :allows_duplicate
      t.boolean :allows_null
      t.boolean :is_read_only
      t.boolean :is_required

      t.timestamps
    end
  end
end
