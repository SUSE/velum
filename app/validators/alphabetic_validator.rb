# AlphabeticValidator validates that there's only alphabetic digits in a set of
# protected values.
class AlphabeticValidator < ActiveModel::EachValidator
  PROTECTED_VALUES = [:company_name, :company_unit, :country, :state, :city].freeze

  def validate_each(record, attribute, value)
    return unless protected?(record.pillar)
    return if value.nil? || value.match(/^[a-zA-Z\s]+$/)

    record.errors[attribute] << "contains invalid characters"
  end

  protected

  # Returns true if the given value belongs to a protected key.
  def protected?(pillar)
    PROTECTED_VALUES.include? Pillar.all_pillars.invert[pillar]
  end
end
