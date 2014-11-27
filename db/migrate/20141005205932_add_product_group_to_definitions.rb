class AddProductGroupToDefinitions < ActiveRecord::Migration
  def change
    add_column :definitions, :product_groups, :text
  end
end
