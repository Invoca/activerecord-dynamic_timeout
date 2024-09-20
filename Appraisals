# frozen_string_literal: true

require "appraisal/matrix"

appraisal_matrix(activerecord: "6.1") do |activerecord:|
  if activerecord < "7.2"
    gem "sqlite3", "~> 1.4"
  end
end
# appraisal_matrix(activerecord: "6.1", mysql2: { versions: ["~> 0.5"], step: :major })
# appraisal_matrix(activerecord: "6.1", pg: { versions: ["~> 1.5"], step: :major })
#
# appraisal_matrix(activerecord: [">= 6.1", "< 7.2"], sqlite3: { versions: ["~> 1.4"], step: :major })
# appraisal_matrix(activerecord: "7.2", sqlite3: { versions: [">= 1.4"], step: :major })
# appraisal_matrix(activerecord: "7.1", trilogy: { versions: [">= 2.8"], step: :major })
