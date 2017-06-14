# AlphanumericValidator validates that there's only alphabetic digits in a set of
# protected values and alphanumerical digits in another set of protected values.
class AlphanumericValidator < ActiveModel::EachValidator
  ALPHANUMERICAL_VALUES = [:company_name, :company_unit].freeze
  ALPHABETICAL_VALUES   = [:country, :state, :city].freeze
  PROTECTED_VALUES      = (ALPHANUMERICAL_VALUES + ALPHABETICAL_VALUES).freeze

  def validate_each(record, attribute, value)
    # Base case: irrelevant pillar value, or nil value.
    return unless relevant?(record.pillar, value)

    # Pillar values that should contain only alphabetical digits.
    return if contains?(ALPHABETICAL_VALUES, record.pillar) && value.match(/^[a-zA-Z\s]+$/)

    # Pillar values that can contain characters from "space" to "~" in the
    # ASCII table.
    return if contains?(ALPHANUMERICAL_VALUES, record.pillar) && value.match(/^[\x20-\x7e]+$/)

    record.errors[attribute] << "contains invalid characters"
  end

  protected

  # Returns true if the given pillar and value are relevant: non-empty value
  # which happens to be set on a protected key.
  def relevant?(pillar, value)
    !value.nil? && contains?(PROTECTED_VALUES, pillar)
  end

  # Returns true if the given `pillar` value exists in the given array `ary`.
  def contains?(ary, pillar)
    ary.include? Pillar.all_pillars.invert[pillar]
  end
end
