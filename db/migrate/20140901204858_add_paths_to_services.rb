class AddPathsToServices < ActiveRecord::Migration
  def change
    add_column :services, :discover_path, :string
    add_column :services, :lead_path, :string
    add_column :services, :request_parameters, :text
  end
end
