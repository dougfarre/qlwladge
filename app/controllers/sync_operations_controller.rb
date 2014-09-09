class SyncOperationsController < ApplicationController
  before_action :set_sync_operation, 
    only: [:show, :edit, :update, :destroy, :source_data_grid, :update_grid_row]

  # GET /sync_operations
  # GET /sync_operations.json
  def index
    @sync_operations = SyncOperation.all
  end

  # GET /sync_operations/1
  # GET /sync_operations/1.json
  def show
    js source_data_grid_link: source_data_grid_definition_sync_operation_path(@definition, @sync_operation)
    js update_grid_link: update_grid_row_definition_sync_operation_path(@definition, @sync_operation)
  end

  # GET /sync_operations/new
  def new
    @definition = Definition.find(params[:definition_id])
    @sync_operation = @definition.sync_operations.build
  end

  # GET /sync_operations/1/edit
  def edit
  end

  # POST /sync_operations
  # POST /sync_operations.json
  def create
    @definition = Definition.find(params[:definition_id])
    @sync_operation = @definition.sync_operations.build(sync_operation_params)

    respond_to do |format|
      if @sync_operation.save
        format.html { redirect_to definition_sync_operation_path(@definition, @sync_operation), notice: 'Sync operation was successfully created.' }
        format.json { render :show, status: :created, location: @sync_operation }
      else
        format.html { render :new }
        format.json { render json: @sync_operation.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /sync_operations/1
  # PATCH/PUT /sync_operations/1.json
  def update
    @service = @definition.service
    respond_to do |format|
      if @sync_operation.sync
        format.html { redirect_to definition_sync_operation_path(@definition, @sync_operation), notice: 'Sync operation was successfully updated.' }
        format.json { render :show, status: :ok, location: @sync_operation }
      else
        format.html { redirect_to edit_service_path(@definition.service), notice: @definition.service.errors[:base] }
        format.json { render json: @sync_operation.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sync_operations/1
  # DELETE /sync_operations/1.json
  def destroy
    @sync_operation.destroy
    respond_to do |format|
      format.html { redirect_to sync_operations_url, notice: 'Sync operation was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # Custom AJAX endpoints

  def source_data_grid
    editable = @sync_operation.response.blank?
    values = @definition.service.build_api_input(@definition.mappings, @sync_operation.source_data)
    status = ''

    metadata = [{
      'name' => 'status',
      'label' => 'Status',
      'editable' => false
    }] + @definition.mappings.map.with_index{|mapping| {
      'name' => mapping.destination_field.name,
      'label' => mapping.destination_field.display_name,
      'datatype' => 'string', #mapping.destination_field.data_type,
      'editable' => editable
    } if mapping.destination_field }.compact!

    data = values.map.with_index{|mapped_row, i| {
      'id' => i + 1,
      'values' => mapped_row.merge({'status' => status})
    }}

    render json: {'metadata' => metadata, "data" => data}.to_json
  end

  def update_grid_row
    status = 'error'
    mapped_data = @definition.service.build_api_input(@definition.mappings, @sync_operation.source_data)
    old_mapped_row = get_mapped_row(mapped_data)
    new_mapped_row = grid_row_params['new_row']
    status = 'ok' if @sync_operation.change_source_data(old_mapped_row, new_mapped_row)
    render plain: status
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_sync_operation
    @sync_operation = SyncOperation.find(params[:id])
    @definition = Definition.find(params[:definition_id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def sync_operation_params
    params.require(:sync_operation).permit([:source_file, :source_file_cache ])
  end

  def grid_row_params
    params.require(:grid_row).permit!
  end

  def get_mapped_row(mapped_data)
    mapped_data.detect do |current_row|
        grid_row_params['old_row'] if row_compare(current_row, grid_row_params['old_row'].except!('status'))
    end
  end

  def row_compare(current_row, comparison_row)
    boolean_array = comparison_row.keys.map{|key| comparison_row[key] == current_row[key]}
    !boolean_array.include? false
  end
  
end
