# Settings::BaseCertificateController extract common methods for certificate
# handling in controllers.
#
# It expects the instance to be assigned to @certificate_holder and will
# set this variable before the `update` & `delete` routes.
#
# Subclasses are expected to overwrite the following methods:
#
# - @certificate_holder: the instance that holds the reference to the
#                        certificate
#
# - certificate_holder_type: return the class that will hold a reference to a
#                       certificate
#
# - certificate_holder_params: parameters that can be used to create a new
#                              certificate_holder model
#
# - certificate_holder_update_params: parameters that can be used to update the
#                                     certificate_holder model
class Settings::BaseCertificateController < SettingsController
  before_action :set_certificate_holder, except: [:index, :new, :create]

  attr_accessor :certificate_holder

  def new
    @certificate_holder = certificate_holder_type.new
    @cert = Certificate.new
  end

  def create
    @certificate_holder = certificate_holder_type.new(
      certificate_holder_params.except(:certificate)
    )
    @cert = Certificate.find_or_initialize_by(certificate: certificate_param)

    ActiveRecord::Base.transaction do
      @certificate_holder.save!
      create_or_update_certificate! if certificate_param.present?
    end

    redirect_to [:settings, @certificate_holder],
                notice: "#{@certificate_holder.class} was successfully created."
  rescue ActiveRecord::RecordInvalid
    render action: :new, status: :unprocessable_entity
  end

  def edit
    @cert = @certificate_holder.certificate || Certificate.new
  end

  def update
    @cert = @certificate_holder.certificate || Certificate.new(certificate: certificate_param)

    ActiveRecord::Base.transaction do
      @certificate_holder.update_attributes!(certificate_holder_update_params)

      if certificate_param.present?
        create_or_update_certificate!
      elsif @certificate_holder.certificate.present?
        @certificate_holder.certificate.destroy!
      end
    end

    redirect_to [:settings, @certificate_holder],
                notice: "#{@certificate_holder.class} was successfully updated."
  rescue ActiveRecord::RecordInvalid
    render action: :edit, status: :unprocessable_entity
  end

  protected

  # Class of ActiveRecord model that will hold the certificate
  #
  # @return [Class] Class of the object that will hold the certificate
  def certificate_holder_type
    raise NotImplementedError,
          "#{self.class.name}#certificate_holder_type is an abstract method."
  end

  # Form parameters that can be used to create instantiate the
  # certificate_holder_type
  #
  # @return [ActiveController::StrongParameters]
  def certificate_holder_params
    raise NotImplementedError,
          "#{self.class.name}#certificate_holder_update_params is an abstract method."
  end

  # Form parameters that can be used to update the
  # certificate_holder instance
  #
  # @return [ActiveController::StrongParameters]
  def certificate_holder_update_params
    raise NotImplementedError,
          "#{self.class.name}#certificate_holder_update_params is an abstract method."
  end

  def create_or_update_certificate!
    if @cert.new_record?
      @cert.save!
      CertificateService.create!(service: certificate_holder, certificate: @cert)
    else
      @cert.update_attributes!(certificate: certificate_param)
    end
  end

  def set_certificate_holder
    @certificate_holder = certificate_holder_type.find(params[:id])
  end
end
