require "rails_helper"
require "velum/kubernetes"

describe Velum::Kubernetes do
  it "returns a KubeConfig struct" do
    allow(Velum::Salt).to receive(:call)
      .and_return([nil, "return" => [file: "some file content"]])

    expect(described_class.kubeconfig).to be_a(Velum::Kubernetes::KubeConfig)
  end
end
