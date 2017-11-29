# The superclass of all the models.
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
