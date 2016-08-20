require 'uri'
require 'open-uri'

class Submission < ApplicationRecord
  validates :url, presence: true, length: { maximum: 2048 },
                    uniqueness: {case_sensitive: false}
  validate :valid_uri?
  before_save :getTitleUrl, :downcase_attributes, :smart_add_url_protocol

  # def self.get_recipe(url)
  #   url = "http://www.foodista.com/recipe/WZ82F5RR/saffron-infused-rice-pudding-with-sweetened-whole-wheat-pancakes"
  #   response = Unirest.get "https://spoonacular-recipe-food-nutrition-v1.p.mashape.com/recipes/extract?forceExtraction=false&url=#{url}",
  #   headers:{
  #     "X-Mashape-Key" => ENV['SPOONACULAR_API']
  #   }
  #   return response
  # end

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
