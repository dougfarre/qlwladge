class AddMitsFieldsToDestinationFields < ActiveRecord::Migration
  def change
    add_column :destination_fields, :mits_unit_type, :string
    add_column :destination_fields, :mits_quantity_type, :string
    add_column :destination_fields, :mits_tag_id, :string
    add_column :destination_fields, :mits_label, :string
  end
end
