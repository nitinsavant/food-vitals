require 'uri'
require 'open-uri'

class Submission < ApplicationRecord
  before_validation :smart_add_url_protocol
  validates :url, presence: true, length: { maximum: 2048 },
                    uniqueness: {case_sensitive: false}
  validate :valid_uri?
  before_save :getTitleUrl, :downcase_attributes

  private

  def valid_uri?
    URI.parse(url)
    url.kind_of?(URI::HTTP)
  rescue URI::InvalidURIError
    errors.add(:url, "Please submit a valid link.")
  end

  def downcase_attributes
    self.url = url.downcase
  end

  def getTitleUrl
    noko_object = Nokogiri::HTML(open(self.url))
    self.title = noko_object.css("title")[0].text
  end

  def smart_add_url_protocol
    unless self.url[/\Ahttp:\/\//] || self.url[/\Ahttps:\/\//]
      self.url = "http://#{self.url}"
    end
  end

end
