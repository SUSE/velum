# frozen_string_literal: true

# ApplicationHelper contains all the view helpers.
module ApplicationHelper
  # Render the user profile picture depending on the gravatar configuration.
  def user_image_tag(owner)
    email = owner.nil? ? nil : owner.email
    gravatar_image_tag(email)
  end

  # render_bare_node renders a Kubernetes node in HTML.
  def render_bare_node(node)
    render_hash(node[:table])
  end

  protected

  # render_hash renders the given hash in HTML.
  def render_hash(hsh)
    res = "<ul>"

    hsh.each do |k, v|
      res += "<li><b>#{k}</b>"
      res += if v.is_a? Hash
        ":</li>" + render_hash(v)
      else
        ": #{v}</li>"
      end
    end

    res + "</ul>"
  end
end
