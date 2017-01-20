# Minion represents the minions that have been registered in this application.
class Minion < ApplicationRecord
  default_scope { order hostname: :asc }
end
