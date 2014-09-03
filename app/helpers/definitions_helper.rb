module DefinitionsHelper

  def get_qualified_destination_fields(definition)
    definition.destination_fields.map{|d_field|
      [d_field.display_name, d_field.id] if d_field.is_qualified
    }.compact
  end
end
