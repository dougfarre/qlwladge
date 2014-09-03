module DefinitionsHelper

  def get_qualified_destination_fields(definition)
    definition.destination_fields.map{|d_field|
     d_field if d_field.is_qualified
    }.compact
  end

  def get_hidden_destination_fields(definition)
    definition.destination_fields.map do |d_field|
      attributes = {
        'id' => d_field.id.to_s,
        'name' => d_field.name,
        'description' => d_field.description,
        'data_type' => d_field.data_type,
        'allows_null' => d_field.allows_null.to_s,
        'is_required' => d_field.is_required.to_s
      }

      hidden_field_tag('d_field_' + d_field.id.to_s, attributes.to_json)
    end
  end
end
