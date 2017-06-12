# frozen_string_literal: true

require "velum/salt"

# UpdatesController handles all the interaction with the updates of all nodes.
class UpdatesController < ApplicationController
  before_action :admin_needs_update, only: :create

  # Reboot the admin node.
  def create
    ::Velum::Salt.call(
      action:  "cmd.run",
      targets: "admin",
      arg:     "systemctl reboot"
    )

    redirect_to root_path, flash: { info: "Rebooting..." }
  end

  protected

  def admin_needs_update
    needed, failed = ::Velum::Salt.update_status(targets: "*", cached: true)
    status = Minion.computed_status("admin", needed, failed)

    return if status == Minion.statuses[:update_needed] ||
        status == Minion.statuses[:update_failed]

    redirect_to root_path, flash: { error: "There's no need to update" }
  end
end
