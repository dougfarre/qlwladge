class RenameDefinitionInRequestParams < ActiveRecord::Migration
  def change
    rename_column :request_parameters, :definition, :description
  end
end
