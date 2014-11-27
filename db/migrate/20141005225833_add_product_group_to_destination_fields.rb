class AddProductGroupToDestinationFields < ActiveRecord::Migration
  def change
    add_column :destination_fields, :mits_tag, :string
  end
end
