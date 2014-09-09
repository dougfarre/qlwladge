class DefinitionsController < ApplicationController
  before_action :set_definition, only: [:show, :edit, :destroy, :update]

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
    redirect_to edit_service_path(@service) unless @definition.destination_fields

    @definition.mappings = build_mappings
    redirect_to edit_service_definition_path(@service, @definition) unless @definition.mappings

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
    update_definition_request_params and return unless definition_params.blank?
    update_definition_mappings and return unless mapping_params.blank?

    respond_to do |format|
      format.html { render :edit, notice: "No data submitted for update" }
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
    #params.permit(definition: [:description, :source_file, :source_file_cache ])
    #fi:c
    params.require(:definition).permit(:description, :source_file, :source_file_cache) rescue nil
  end

  def request_value_parameters
    params.require(:request_parameters).permit!
  end

  def mapping_params
    source_headers = @definition.mappings.map(&:source_header)
    params.require(:mapping).permit(source_headers)
  end

  def mappings_params
    params.require(:mappings).permit(:source_key) rescue nil
  end

  # Do any additional processing here (like standardizing the data type)
  def build_destination_fields
    @service.get_discovery.map{|f| DestinationField.new(f) } rescue nil
  end

  def build_mappings
    @definition.get_headers.map{|header| Mapping.new(source_header: header)}
  end

  def update_definition_request_params
    respond_to do |format|
      if @definition.update(definition_params)
         format.html { redirect_to service_definition_path(@service, @definition), notice: 'Definition request parameters were successfully updated.' }
         format.json { render :show, status: :ok, location: @definition }
      else
        format.html { render :edit }
        format.json { render json: @definition.errors, status: :unprocessable_entity }
      end
    end
  end

  def update_definition_mappings
    mapping_params.each do |header, destination_field_id|
      mapping = @definition.mappings.detect{|x| x.source_header == header}
      mapping.destination_field_id = destination_field_id
    end

    unless mappings_params.blank?
      mapping_id = mappings_params['source_key'].to_i
      mapping = @definition.mappings.detect{|x| x.id == mapping_id}
      mapping.source_key = true
    end

    respond_to do |format|
      if @definition.save
         format.html { redirect_to service_definition_path(@service, @definition), notice: 'Definition mappings were successfully updated.' }
         format.json { render :show, status: :ok, location: @definition }
      else
        format.html { render :edit }
        format.json { render json: @definition.errors, status: :unprocessable_entity }
      end
    end
  end
end
