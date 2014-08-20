class RenameFieldsToDestinationFields < ActiveRecord::Migration
  def change
    rename_table :fields, :destination_fields
  end
end
