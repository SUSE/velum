# generic polymorphic model for all kinds of certificates
# rubocop:disable Rails/HasManyOrHasOneDependent
class Certificate < ActiveRecord::Base
  has_many :docker_registries, as: :certifiable
  validates :certificate, presence: true
end
# rubocop:enable Rails/HasManyOrHasOneDependent
