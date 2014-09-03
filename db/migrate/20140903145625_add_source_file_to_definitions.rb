class AddSourceFileToDefinitions < ActiveRecord::Migration
  def change
    add_column :definitions, :source_file, :string
  end
end
