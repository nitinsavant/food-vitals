require 'uri'
require 'open-uri'
require 'openssl'
require 'base64'
require 'digest/md5'
require 'net/http'
require 'ext/string'

class Submission < ApplicationRecord
  serialize :spoon_recipe_response
  validates :url, presence: true, length: { maximum: 2048 }, uniqueness: { case_sensitive: false }
  validate :valid_uri?
  before_save :getTitleUrl, :downcase_attributes, :smart_add_url_protocol, :get_recipe_from_spoon

  def self.fatsecret_ingredient_lookup(id)
    http_method = 'GET'
    REQUEST_URL = "http://platform.fatsecret.com/rest/server.api"
    # Parameters are written in the format "name=value" and sorted using
    # lexicographical byte value ordering, first by name and then by value.
    oauth_params = {
        :oauth_consumer_key => ENV['FATSECRET_CONSUMER_API_KEY'],
        :oauth_nonce => Digest::MD5.hexdigest(rand(11).to_s),
        :oauth_signature_method => "HMAC-SHA1",
        :oauth_timestamp => Time.now.to_i,
        :oauth_version => "1.0",
        :method => "foods.search",
        :search_expression => expression
    }
    sorted_oauth_params = oauth_params.sort {|a, b| a.first.to_s <=> b.first.to_s}
    # Finally the parameters are concatenated in their sorted order into a
    # single string, each name-value pair separated by an '&' character.
    concat_oauth_params = sorted_oauth_params.collect{|pair| "#{pair.first}=#{pair.last}"}.join('&')
    # Request parameters (i.e. the HTTP Method, Request URL and Normalized Parameters) must be
    # encoded using the [RFC3986] percent-encoding (%xx) mechanism and concatenated by '&' character.
    request_params = [http_method.esc, REQUEST_URL.esc, concat_oauth_params.esc]
    signature_base_string = request_params.join("&")
    list = []
    sorted_oauth_params.inject(list) {|arr, pair| arr << "#{pair.first.to_s}=#{pair.last}"}
    http_params = list.join("&")
    # Use the HMAC-SHA1 signature algorithm as defined by the [RFC2104] to sign the request where
    # text is the Signature Base String and key is the concatenated values of the Consumer Secret
    # and Access Secret separated by an '&' character (show '&' even if Access Secret is empty
    # as some methods do not require an Access Token).
    token = ''
    SECRET = ENV['FATSECRET_CONSUMER_SHARED_SECRET']
    secret = "#{SECRET.esc}&#{token.esc}"
    oauth_sign = Base64.encode64(OpenSSL::HMAC.digest('sha1', secret, signature_base_string)).gsub(/\n/,'')
    # The calculated digest octet string, first base64-encoded per [RFC2045], then escaped
    # using the [RFC3986] percent-encoding (%xx) mechanism is the oauth_signature.
    oauth_sign_esc = oauth_sign.esc
    parts = http_params.split('&')
    parts << "oauth_signature=#{oauth_sign_esc}"
    uri = URI.parse("#{REQUEST_URL}?#{parts.join('&')}")
    results = Net::HTTP.get(uri)
    # Retrieve ingredients_array from database that was called from Spoonacular
    ingredients_array = Submission.find(id).spoon_recipe_response
    ingredients_array["extendedIngredients"].map{|hash| hash["name"]}
    ingredients_array.each do |ingredient|

    end
    results = search('sugar')
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
