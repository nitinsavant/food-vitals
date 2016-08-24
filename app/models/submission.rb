require 'uri'
require 'open-uri'

class Submission < ApplicationRecord
  serialize :spoon_recipe_response
  validates :url, presence: true, length: { maximum: 2048 }, uniqueness: { case_sensitive: false }
  validate :valid_uri?
  before_save :getTitleUrl, :downcase_attributes, :smart_add_url_protocol, :get_recipe_from_spoon

  def self.get_ingredients_from_response(id)
    ingredients_array = Submission.find(id).spoon_recipe_response
    ingredients_array["extendedIngredients"].map{|hash| hash["originalString"]}
  end

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

  def get_recipe_from_spoon
    if self.spoon_recipe_response.nil?
      url = self.url
      response = Unirest.get "https://spoonacular-recipe-food-nutrition-v1.p.mashape.com/recipes/extract?forceExtraction=false&url=#{url}",
      headers:{
        "X-Mashape-Key" => ENV['SPOONACULAR_API']
      }
      self.spoon_recipe_response = response.body
    end
  end

  def smart_add_url_protocol
    unless self.url[/\Ahttp:\/\//] || self.url[/\Ahttps:\/\//]
      self.url = "http://#{self.url}"
    end
  end

end
