class AddMoreMitsFieldsToDestinationFields < ActiveRecord::Migration
  def change
    add_column :destination_fields, :mits_product_id, :string
    add_column :destination_fields, :mits_product_type, :string
    add_column :destination_fields, :mits_record_id, :string
  end
end
