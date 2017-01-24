# frozen_string_literal: true

# ApplicationHelper contains all the view helpers.
module ApplicationHelper
  # Render the user profile picture depending on the gravatar configuration.
  def user_image_tag(owner)
    email = owner.nil? ? nil : owner.email
    gravatar_image_tag(email)
  end
end
