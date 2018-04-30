# Store selected salt job ids, and record on their result
class SaltJob < ActiveRecord::Base
  validates :jid, uniqueness: true

  scope :all_open, -> { where(retcode: nil) }
  scope :jids, -> { pluck(:jid) }

  def complete!(retcode = 0, master_trace: nil, minion_trace: nil)
    changes = { retcode: retcode }
    changes[:master_trace] = master_trace if master_trace
    changes[:minion_trace] = minion_trace if minion_trace
    update_attributes! changes

    parse_upstream_error if failed?
  end

  def completed?
    retcode.present?
  end

  def succeeded?
    completed? && retcode.zero?
  end

  def failed?
    completed? && !retcode.zero?
  end

  def parse_upstream_error
    return if master_trace.blank? && minion_trace.blank?
    errors.add(:base, "Please check `/var/log/salt/minion` for details.")
  end
end
