require "rails_helper"

# Required subclass to gain access to the protected methods.
class TestCertificate < Settings::BaseCertificateController
  def certificate_holder_type
    super
  end

  def certificate_holder_params
    super
  end

  def certificate_holder_update_params
    super
  end
end

RSpec.describe Settings::BaseCertificateController, type: :controller do
  let(:base_certificate_controller) { TestCertificate.new }

  describe "Acquire certificate holder" do
    it "Can not call certificate holder type in the super class" do
      expect do
        base_certificate_controller.certificate_holder_type
      end.to raise_error(NotImplementedError)
    end

    it "Can not call certificate holder params in the super class" do
      expect do
        base_certificate_controller.certificate_holder_params
      end.to raise_error(NotImplementedError)
    end

    it "Can not call certificate holder update params in the super class" do
      expect do
        base_certificate_controller.certificate_holder_update_params
      end.to raise_error(NotImplementedError)
    end
  end
end
