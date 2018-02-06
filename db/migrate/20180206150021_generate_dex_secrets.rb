require 'securerandom'

class GenerateDexSecrets < ActiveRecord::Migration
  def up
    Pillar.find_or_create_by pillar: "dex:client_secrets:kubernetes" do |pillar|
      pillar.value = SecureRandom.uuid
    end
    Pillar.find_or_create_by pillar: "dex:client_secrets:velum" do |pillar|
      pillar.value = SecureRandom.uuid
    end
  end

  def down
    Pillar.where(pillar: "dex:client_secrets:kubernetes").destroy_all
    Pillar.where(pillar: "dex:client_secrets:velum").destroy_all
  end
end
