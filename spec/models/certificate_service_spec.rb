require "rails_helper"

describe CertificateService do
  it { is_expected.to belong_to(:certificate) }
  it { is_expected.to belong_to(:service) }
end
