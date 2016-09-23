require 'uri'
require 'open-uri'
require 'openssl'
require 'base64'
require 'digest/md5'
require 'net/http'
require 'ext/string'

class Submission < ApplicationRecord
  has_many :ingredients, dependent: :destroy
  serialize :spoon_recipe_response
  validates :url, presence: true, length: { maximum: 2048 }, uniqueness: { case_sensitive: false }
  validate :valid_uri?
  before_save :getTitleUrl, :downcase_attributes, :smart_add_url_protocol, :get_recipe_from_spoon

  def self.get_fatsecret_food_ids(id)
    i=0
    food_ids = []
    oauth_check = []
    food_id_array = []
    ingredient_food_id = ""
    xml_response = ""
    # Retrieve ingredients_array from database that was called from Spoonacular
    submission = Submission.find(id)
    spoon_recipe_response = submission.spoon_recipe_response
    ingredients_amounts = spoon_recipe_response["extendedIngredients"].map{|hash| hash.slice("name", "amount") }
    ingredients_amounts.each do |ingredient|
      query_params = {
        :method => 'foods.search',
        :search_expression => ingredient["name"].esc,
        :page_number => 0,
        :max_results => 1
      }
      xml_response, oauth_params = generate_fatsecret_request(query_params)
      doc = Nokogiri::XML(xml_response)
      ingredient_food_id = doc.xpath("/*[name()='foods']/*[name()='food']/*[name()='food_id']").text
      submission.ingredients.create(name: ingredient["name"], food_id: ingredient_food_id, amount: ingredient["amount"])
      oauth_check[i] = oauth_params
      food_id_array[i] = ingredient_food_id
      i += 1
    end
    return ingredients_amounts, oauth_check, food_id_array
  end

  def self.get_fatsecret_nutrition(id)
    i=0
    xml_response_array = []
    xml_response = ""
    fatsecret_food_name = ""
    serving_description = ""
    oauth_check_get = []
    nutrition_facts = []
    food_ids_amounts = Ingredient.where(submission_id: id).pluck(:food_id, :amount).to_a
    food_ids_amounts.each do |food_id, amount|
      query_params = {
        :method => 'food.get',
        :food_id => food_id
      }
      xml_response, oauth_params = generate_fatsecret_request(query_params)
      doc = Nokogiri::XML(xml_response)
      fatsecret_food_name = doc.xpath("/*[name()='food']/*[name()='food_name']").try(:text)
      calories = doc.xpath("/*[name()='food']/*[name()='servings']/*[name()='serving']/*[name()='calories']").first.try(:text)
      carbohydrate = doc.xpath("/*[name()='food']/*[name()='servings']/*[name()='serving']/*[name()='carbohydrate']").first.try(:text)
      protein = doc.xpath("/*[name()='food']/*[name()='servings']/*[name()='serving']/*[name()='protein']").first.try(:text)
      fiber = doc.xpath("/*[name()='food']/*[name()='servings']/*[name()='serving']/*[name()='fiber']").first.try(:text)
      sugar = doc.xpath("/*[name()='food']/*[name()='servings']/*[name()='serving']/*[name()='sugar']").first.try(:text)
      # trans_fat = doc.xpath("/*[name()='food']/*[name()='servings']/*[name()='serving']/*[name()='trans_fat']").first.text
      # serving_description = doc.xpath("/*[name()='food']/*[name()='servings']/*[name()='serving']/*[name()='serving_description']").first.text
      nutrition_facts[i] = [fatsecret_food_name, amount, calories, carbohydrate, protein, fiber, sugar ]
      oauth_check_get[i] = oauth_params
      xml_response_array[i] = xml_response
      i += 1
    end
    return nutrition_facts, xml_response_array, oauth_check_get
  end

  def self.calculate_nutrition(id)
    nutrition_facts, food_ids_amounts, xml_response = get_fatsecret_nutrition(id)
    total_calories = 0
    total_carbs = 0
    total_protein = 0
    total_fiber = 0
    total_sugar = 0
    nutrition_facts.each do |fatsecret_food_name, amount, calories, carbohydrate, protein, fiber, sugar |
      total_calories = total_calories + (amount * calories.to_f)
      total_carbs = total_carbs + (amount * carbohydrate.to_f)
      total_protein = total_protein + (amount * protein.to_f)
      total_fiber = total_fiber + (amount * fiber.to_f)
      total_sugar = total_sugar + (amount * sugar.to_f)
    end
    nutrition_overview = [total_calories.round, total_carbs.round, total_protein.round, total_fiber.round, total_sugar.round]
    return nutrition_facts, nutrition_overview, food_ids_amounts, xml_response
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

  def self.generate_fatsecret_request(query_params)
    http_method = 'GET'
    request_url = "http://platform.fatsecret.com/rest/server.api"
    # digest = OpenSSL::Digest::Digest.new('sha1')
    digest = OpenSSL::Digest::SHA1.new
    oauth_token = ''
    oauth_params = {
        :oauth_consumer_key => ENV['FATSECRET_CONSUMER_API_KEY'],
        :oauth_nonce => Digest::MD5.hexdigest(rand(100).to_s),
        :oauth_signature_method => "HMAC-SHA1",
        :oauth_timestamp => Time.now.to_i,
        :oauth_version => "1.0"
    }
    # Add query paramaters for specific API method to oauth parameters
    oauth_params.merge!(query_params)
    # Parameters are written in the format "name=value" and sorted using
    # lexicographical byte value ordering, first by name and then by value.
    sorted_oauth_params = oauth_params.sort {|a, b| a.first.to_s <=> b.first.to_s}
    # Finally the parameters are concatenated in their sorted order into a
    # single string, each name-value pair separated by an '&' character.
    concat_oauth_params = sorted_oauth_params.collect{|pair| "#{pair.first}=#{pair.last}"}.join('&')
    # Request parameters (i.e. the HTTP Method, Request URL and Normalized Parameters) must be
    # encoded using the [RFC3986] percent-encoding (%xx) mechanism and concatenated by '&' character.
    request_params = [http_method.esc, request_url.esc, concat_oauth_params.esc]
    signature_base_string = request_params.join("&")
    list = []
    sorted_oauth_params.inject(list) {|arr, pair| arr << "#{pair.first.to_s}=#{pair.last}"}
    http_params = list.join("&")
    # Use the HMAC-SHA1 signature algorithm as defined by the [RFC2104] to sign the request where
    # text is the Signature Base String and key is the concatenated values of the Consumer Secret
    # and Access Secret separated by an '&' character (show '&' even if Access Secret is empty
    # as some methods do not require an Access Token).
    shared_secret = ENV['FATSECRET_CONSUMER_SHARED_SECRET']
    secret_token = "#{shared_secret.esc}&#{oauth_token.esc}"
    oauth_sign = Base64.encode64(OpenSSL::HMAC.digest(digest, secret_token, signature_base_string)).gsub(/\n/,'')
    # The calculated digest octet string, first base64-encoded per [RFC2045], then escaped
    # using the [RFC3986] percent-encoding (%xx) mechanism is the oauth_signature.
    oauth_sign = oauth_sign.esc
    parts = http_params.split('&')
    parts << "oauth_signature=#{oauth_sign}"
    uri = URI.parse("#{request_url}?#{parts.join('&')}")
    results = Net::HTTP.get(uri)
    return results, oauth_params
  end

end
