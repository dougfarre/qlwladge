class AddNameToDefinitions < ActiveRecord::Migration
  def change
    add_column :definitions, :description, :string
  end
end
