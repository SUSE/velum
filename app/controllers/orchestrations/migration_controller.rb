# Allows to run migration orchestrations
class Orchestrations::MigrationController < ApplicationController
  def create
    # rubocop:disable Rails/SkipsModelValidations
    Minion.admin.update_all highstate: Minion.highstates[:pending]
    # rubocop:enable Rails/SkipsModelValidations
    Orchestration.run kind: :migration
    redirect_to root_path
  end

  def reboot_nodes
    Minion.mark_pending_migration
    ::Velum::Salt.update_orchestration_after_product_migration

    redirect_to root_path
  end

  def check_mirror
    Velum::Salt.call(
      action:      "cmd.run",
      arg:         "update-checker-migration",
      targets:     "roles:(admin|kube-(master|minion))",
      target_type: "grain_pcre"
    )
    Velum::Salt.call(action: "saltutil.refresh_grains")
    Minion.update_grains
    redirect_to root_path
  end

  def status
    status_code = if Orchestration.migration.in_progress?
      200
    else
      # failed
      500
    end
    render nothing: true, status: status_code
  end
end
