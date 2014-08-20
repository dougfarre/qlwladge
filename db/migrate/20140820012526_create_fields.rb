class CreateFields < ActiveRecord::Migration
  def change
    create_table :fields do |t|
      t.integer :definition_id
      t.string :name
      t.string :display_name
      t.string :description
      t.string :data_type
      t.boolean :allows_null
      t.boolean :read_only
      t.boolean :required

      t.timestamps
    end
  end
end
