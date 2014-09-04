json.array!(@sync_operations) do |sync_operation|
  json.extract! sync_operation, :id
  json.url sync_operation_url(sync_operation, format: :json)
end
