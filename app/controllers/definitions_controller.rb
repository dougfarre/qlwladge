class DefinitionsController < ApplicationController
  before_action :set_definition, only: [:show, :edit, :update, :destroy]

  # GET /definitions/1
  # GET /definitions/1.json
  def show
  end

  # GET /definitions/new
  def new
    @service = Service.find(params[:service_id])
    @definition = @service.definitions.build
  end

  # GET /definitions/1/edit
  def edit
  end

  # POST /definitions
  # POST /definitions.json
  def create
    @service = Service.find(params[:service_id])
    @definition = @service.definitions.build(definition_params)
    @definition.destination_fields = build_destination_fields
    @definition.mappings = build_mappings

    request_value_parameters.each do |key, value|
      request_parameter = @definition.request_parameters.find {|param| param[:name] == key}
      request_parameter.value = value
    end


    respond_to do |format|
      if @definition.save
        format.html { redirect_to service_definition_path(@service, @definition), notice: 'Definition was successfully created.' }
        format.json { render :show, status: :created, location: @definition }
      else
        format.html { render :new }
        format.json { render json: @definition.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /definitions/1
  # PATCH/PUT /definitions/1.json
  def update
    respond_to do |format|
      if @definition.update(definition_params)
        format.html { redirect_to service_definition_path(@definition), notice: 'Definition was successfully updated.' }
        format.json { render :show, status: :ok, location: @definition }
      else
        format.html { render :edit }
        format.json { render json: @definition.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /definitions/1
  # DELETE /definitions/1.json
  def destroy
    @service = @definition.service
    @definition.destroy
    respond_to do |format|
      format.html { redirect_to @service, notice: 'Definition was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_definition
      @definition = Definition.find(params[:id])
      @service = Service.find(params[:service_id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def definition_params
      params.require(:definition).permit(:description, :source_file, :source_file_cache)
    end

    def request_value_parameters
      params.require(:request_parameters).permit!
    end

    # Do any additional processing here (like standardizing the data type)
    def build_destination_fields
      @service.get_discovery.map{|f| DestinationField.new(f) }
    end

    def build_mappings
      @definition.get_headers.map{|header| Mapping.new(source_header: header)}
    end
end
