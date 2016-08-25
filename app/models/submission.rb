require 'uri'
require 'open-uri'
require 'openssl'
require 'base64'
require 'digest/md5'
require 'net/http'

class Submission < ApplicationRecord
  serialize :spoon_recipe_response
  validates :url, presence: true, length: { maximum: 2048 }, uniqueness: { case_sensitive: false }
  validate :valid_uri?
  before_save :getTitleUrl, :downcase_attributes, :smart_add_url_protocol, :get_recipe_from_spoon

  def self.fatsecret_ingredient_lookup(id)
    secret = ENV['FATSECRET_CONSUMER_SHARED_SECRET']
    http_method = 'GET'
    request_url = "http://platform.fatsecret.com/rest/server.api"
    params = {
        :oauth_consumer_key => ENV['FATSECRET_CONSUMER_API_KEY'],
        :oauth_nonce => Digest::MD5.hexdigest(rand(11).to_s),
        :oauth_signature_method => "HMAC-SHA1",
        :oauth_timestamp => Time.now.to_i,
        :oauth_version => "1.0",
        :method => 'foods.search',
        :search_expression => expression
    }
    sorted_params = params.sort {|a, b| a.first.to_s <=> b.first.to_s}
    param_str = sorted_params.collect{|pair| "#{pair.first}=#{pair.last}"}.join('&')

    ingredients_array = Submission.find(id).spoon_recipe_response
    ingredients_array["extendedIngredients"].map{|hash| hash["name"]}

    ingredients_array.each do |ingredient|

      list = [http_method.esc, request_url.esc, param_str.esc]
      base = list.join("&")
      pairs = params.sort {|a, b| a.first.to_s <=> b.first.to_s}
      list = []
      pairs.inject(list) {|arr, pair| arr << "#{pair.first.to_s}=#{pair.last}"}
      http_params = list.join("&")
      token = ''
      secret = "#{SECRET.esc}&#{token.esc}"
      sign = Base64.encode64(OpenSSL::HMAC.digest('sha1',secret, base)).gsub(/\n/,'')
      sig = CGI.escape(sign).gsub("%7E", "~").gsub("+", "%20")
      parts = http_params.split('&')
      parts << "oauth_signature=#{sig}"
      uri = URI.parse("#{request_url}?#{parts.join('&')}")
      results = Net::HTTP.get(uri)
    end
    return "nutrition facts"
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
