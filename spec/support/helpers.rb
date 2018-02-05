# frozen_string_literal: true
# A simple module containing some helper methods for acceptance tests.
module Helpers
  # Login the given user and visit the root url.
  def login(user)
    login_as user, scope: :user
    visit root_url
  end

  # Returns a String containing the id of the currently active element.
  def focused_element_id
    page.evaluate_script("document.activeElement.id")
  end

  # Returns a boolean regarding whether the given selector matches an element
  # that is currently disabled.
  def disabled?(selector)
    page.evaluate_script("$('#{selector}').attr('disabled')") == "disabled"
  end

  # click on `selector element when enabled
  def click_on_when_enabled(selector)
    find("#{selector}:not([disabled])", match: :first).click
  end
end

def click_instance_type_radio(instance_type)
  page.execute_script('$("' + instance_type_radio_finder(instance_type) + '").click()')
end

def instance_type_radio_finder(instance_type)
  [
    "input[type='radio']",
    "[name='cloud_cluster[instance_type]']",
    "[value='#{instance_type.key}']"
  ].join
end

RSpec.configure { |config| config.include Helpers, type: :feature }
