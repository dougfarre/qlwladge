class AddGroupAttrsToMappings < ActiveRecord::Migration
  def change
    add_column :mappings, :groupie_type, :string
    add_column :mappings, :groupie_id, :string
    add_column :mappings, :groupie_unit, :string
  end
end
