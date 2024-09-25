# frozen_string_literal: true

require "appraisal/matrix"

appraisal_matrix(activerecord: "6.1") do |activerecord:|
  if activerecord < "7.1"
    gem "sqlite3", "~> 1.4"
  end
end
