class SyncOperationsController < ApplicationController
  before_action :set_sync_operation, only: [:show, :edit, :update, :destroy]

  # GET /sync_operations
  # GET /sync_operations.json
  def index
    @sync_operations = SyncOperation.all
  end

  # GET /sync_operations/1
  # GET /sync_operations/1.json
  def show
  end

  # GET /sync_operations/new
  def new
    @sync_operation = SyncOperation.new
  end

  # GET /sync_operations/1/edit
  def edit
  end

  # POST /sync_operations
  # POST /sync_operations.json
  def create
    @sync_operation = @definition.sync_operations.build(sync_operation_params)

    respond_to do |format|
      if @sync_operation.save
        format.html { redirect_to definition_sync_operation_path(@sync_operation), notice: 'Sync operation was successfully created.' }
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
    respond_to do |format|
      if @sync_operation.update(sync_operation_params)
        format.html { redirect_to @sync_operation, notice: 'Sync operation was successfully updated.' }
        format.json { render :show, status: :ok, location: @sync_operation }
      else
        format.html { render :edit }
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
end
