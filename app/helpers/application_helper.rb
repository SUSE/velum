# ApplicationHelper contains all the view helpers.
module ApplicationHelper
  # Render the user profile picture depending on the gravatar configuration.
  def user_image_tag(owner)
    email = owner.nil? ? nil : owner.email
    gravatar_image_tag(email)
  end

  def any_minion?
    Minion.any?
  end

  # setup means the setup phase was completed
  def setup_done?
    Pillar.exists? pillar: Pillar.all_pillars[:apiserver]
  end

  def can_download_kubeconfig?
    masters_applied_count = Minion.where(role:      Minion.roles[:master],
                                         highstate: Minion.highstates[:applied]).count
    masters_count = Minion.where(role: Minion.roles[:master]).count
    masters_applied = masters_count == masters_applied_count

    setup_done? && masters_applied
  end

  def active_class?(path_or_bool)
    case path_or_bool
    when String
      "active" if current_page?(path_or_bool)
    when TrueClass
      "active"
    end
  end

  def error_class_for(model, field)
    "has-error" if model.errors[field].present?
  end

  def error_messages_for(model, field)
    messages = model.errors.full_messages_for(field) || []
    capture do
      messages.map do |m|
        concat content_tag(:span, m, class: "help-block")
      end
    end
  end

  def product_name
    Rails.configuration.x.product.name
  end

  def product_version
    Rails.configuration.x.product.version
  end
end
