module Velum
  # ViewHelpers adds some methods to view specs.
  module ViewHelpers
    # link? returns true if the given element is a link that points to the given
    # path and that it has the given contents.
    def link?(element, path, contents)
      return false if element.name != "a"

      # Check the href attribute
      given_path = element.attribute("href").value.strip
      return false if given_path != path

      # And finally the text
      element.children[0].text.strip == contents
    end

    # form_request returns true if the given element is a form that submits to
    # the given path with the given method.
    def form_request(element, method, path)
      # Nokogiri is a bit weird with forms...
      form = element[0]

      return false if form.name != "form"

      # Check the action attribute
      m = form.attribute("method").value.strip
      return false if m != method.to_s.downcase

      # And finally the path
      form.attribute("action").value.strip == path
    end
  end
end

RSpec.configure { |cfg| cfg.include Velum::ViewHelpers, type: :view }
