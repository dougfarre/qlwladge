class AddSourceKeywHeaderToMappings < ActiveRecord::Migration
  def change
    add_column :mappings, :source_key, :boolean
  end
end
