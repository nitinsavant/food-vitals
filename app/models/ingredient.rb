class Ingredient < ApplicationRecord
  belongs_to :submission
  validates :submission_id, presence: true
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :food_id, presence: true
end
