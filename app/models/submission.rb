require 'uri'

class Submission < ApplicationRecord
  validates :url, presence: true, length: { maximum: 2048 },
                    uniqueness: {case_sensitive: false}
  validate :valid_uri?

  def valid_uri?
    URI.parse(url)
    url.kind_of?(URI::HTTP)
  rescue URI::InvalidURIError
    errors.add(:url, "Please submit a valid link.")
  end

end
