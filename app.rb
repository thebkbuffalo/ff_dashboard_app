require 'sinatra/base'
require 'json'
require 'pry'
require 'httparty'
require 'redis'
require 'securerandom'


class App < Sinatra::Base

  ########################
  # Configuration
  ########################

  configure do
    enable :logging
    enable :method_override
    enable :sessions
    set :session_secret, 'super secret'
    uri = URI.parse(ENV["REDISTOGO_URL"])
    $redis = Redis.new({:host => uri.host,
                        :port => uri.port,
                        :password => uri.password})
    $redis.flushdb
  end

  before do
    logger.info "Request Headers: #{headers}"
    logger.warn "Params: #{params}"
  end

  after do
    logger.info "Response Headers: #{response.headers}"
  end

  ########################
  # API Keys
  #######################

  KEY = "53bbd3a7cce7cbbcedc67e22259f12ee:4:69767384"
  CALLBACK_URI = "http://127.0.0.1/profile"


  ########################
  # GET Routes
  ########################

  get('/') do

    render(:erb, :index)
  end

  get('/profile') do
    render(:erb, :profile)
  end

  get('/dashboard_form') do
    if params[:sent] == "true"
      @show_submit_success_message = true
    end
    # @feeds = get_from_redis(:feeds)
    render(:erb, :dashboard_form)
  end

  # get('/profile') do
  #   base_url = "http://api.nytimes.com/svc/search/v2/articlesearch.json"
  #   query = "football"
  #   begin_date = 20140904
  #   end_date = 20141131
  #   @url = "#{base_url}?q=#{query}&begin_date=#{begin_date}&end_date=#{end_date}&api-key=#{KEY}&callback=#{CALLBACK_URI}"
  #   response = HTTParty.get
  #   render(:erb, :profile)
  # end

  ##################################
  # POST Routes
  ##################################

  post('/dashboard_form') do
    new_feed = {
      feeds: params[@key]
    }

    post_to_redis(new_feed)
  binding.pry
    redirect to('/dashboard_form?sent=true')

  end

  ###################################
  # REDIS Methods
  ###################################

  def post_to_redis(feeds)
    number = $redis.keys("*feeds*").count
    key = "feeds:#{number + 1}"
    $redis.set(key, feeds.to_json)
  end



  def get_from_redis(redis_id)
    model = JSON.parse($redis.get(redis_id))
    model[:feeds] = redis_id
    model
  end


end # ends class
