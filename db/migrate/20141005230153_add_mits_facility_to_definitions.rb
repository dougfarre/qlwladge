class AddMitsFacilityToDefinitions < ActiveRecord::Migration
  def change
    add_column :definitions, :mits_facility, :string
  end
end
