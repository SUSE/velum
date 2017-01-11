class Minion < ApplicationRecord

  default_scope { order hostname: :asc }

end
