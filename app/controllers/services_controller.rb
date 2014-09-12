class ServicesController < ApplicationController
  before_action :set_service, only: [:show, :edit, :update, :destroy]

  # GET /services
  # GET /services.json
  def index
    @services = current_user.services.map{|s| s.becomes(s.name.constantize)}
  end

  # GET /services/1
  # GET /services/1.json
  def show
  end

  # GET /services/new
  def new
    @service = Service.new(name: service_params[:name])
    this is where the redirect goes!
  end

  # GET /services/1/edit
  def edit
  end

  # POST /services
  # POST /services.json
  def create
    @service = Service.new(name: service_params[:name])
    @service = @service.becomes(service_params[:name].constantize) if @service.valid?
    @service.assign_attributes(service_params)
    @service.user = current_user

    respond_to do |format|
      if @service.save
        @service.authenticate
        format.html { redirect_to @service, notice: get_update_message('created') }
        format.json { render :show, status: :created, location: @service }
      else
        format.html { render :new }
        format.json { render json: @service.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /services/1
  # PATCH/PUT /services/1.json
  def update
    respond_to do |format|
      if @service.update(service_params)
        @service.authenticate
        format.html { redirect_to @service, notice: get_update_message('updated') }
        format.json { render :show, status: :ok, location: @service }
      else
        format.html { render :edit }
        format.json { render json: @service.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /services/1
  # DELETE /services/1.json
  def destroy
    @service.destroy
    respond_to do |format|
      format.html { redirect_to services_url, notice: 'Service was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def oauth2_callback

  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_service
    @service = Service.find(params[:id])
    @service = @service.becomes(@service.type.constantize) if @service.valid?
  end

  def get_update_message(action)
    'Service was successfully ' + action + '. ' +
      'The new Auth Status is: ' + @service.auth_status + '.'
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def service_params
    params
      .require(:service)
      .permit(:service, :name, :api_domain, :api_path,
        :auth_domain, :auth_path, :auth_type, :auth_user,
        :app_api_key, :app_api_secret,
        :custom_client_id, :custom_client_secret,
        :custom_domain, :service)
  end
end
