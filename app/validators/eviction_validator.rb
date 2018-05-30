# Evictionvalidator checks the syntax for hard eviction policies. Some valid
# policies would be: "memory.available<10Mi" or "nodefs.inodesFree<10.6%".
class EvictionValidator < ActiveModel::EachValidator
  INVALID_SYNTAX = "`kubelet:eviction-hard` has to follow a syntax like " \
                   "'memory.available<10%'".freeze

  NUMBER_REGEXP      = /(\d+(\.\d+)?(e\d+)?)/
  NUM_OR_PERC_REGEXP = /\A#{NUMBER_REGEXP}%?\z/
  BYTES_REGEXP       = /\A#{NUMBER_REGEXP}([EPTGMK]i?)?\z/

  # validate_each only validates the pillar value for `kubelet:eviction-hard`.
  def validate_each(record, attribute, value)
    return if attribute.to_sym != :value
    return if record.pillar != "kubelet:eviction-hard"

    # According to `OpForSignal` from `pkg/kubelet/eviction/api/types.go`, the
    # only supported operator for now is "<". This may change in the future if
    # they introduce other operations like `memory.consumed>10Gi`.
    parts = value.split("<")
    if parts.size != 2
      record.errors.add(:value, INVALID_SYNTAX)
      return
    end

    # At this point we can have errors on both sides of the comparison. Do not
    # return early so we can fetch as many errors as possible.
    lval(record, parts.first)
    rval(record, parts.last)
  end

  protected

  # lval checks the syntax of the left value from the comparison.
  def lval(record, val)
    components = val.split(".")

    case components.first
    when "memory"
      validate_lval(record, components.first, components[1], ["available"])
    when "nodefs", "imagefs"
      validate_lval(record, components.first, components[1], %w[available inodesFree])
    else
      unknown!(record, components.first)
    end
  end

  # validate_lval will set an error on the given record if the given method is
  # blank or not supported.
  def validate_lval(record, component, method, supported)
    if method.blank?
      eg = "#{component}.#{supported.first}"
      record.errors.add(:value, "`#{component}` requires something like `#{eg}`")
    elsif !supported.include?(method)
      unknown!(record, component, method)
    end
  end

  # rval checks the syntax of the right value from the comparison.
  def rval(record, val)
    return if val =~ NUM_OR_PERC_REGEXP
    return if val =~ BYTES_REGEXP

    record.errors.add(:value, "invalid syntax for right side " \
                              "(i.e. expected something like `1.5Gi` or `10%`)")
  end

  # unknown! sets an error for unknown components or options. If `option` is
  # left blank, then it's assumed that the component is the thing unknown.
  def unknown!(record, component, option = "")
    if option.blank?
      record.errors.add(:value, "unknown component `#{component}`")
    else
      record.errors.add(:value, "unknown `#{component}.#{option}` option")
    end
  end
end
