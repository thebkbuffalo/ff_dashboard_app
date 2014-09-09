require 'sinatra/base'
require 'json'
require 'pry'
require 'httparty'
require 'redis'
require 'securerandom'
require 'uri'
require 'open-uri'
require 'twitter'
require 'rss'
require 'feedjira'



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
    @@users = []
     # $redis.flushdb
     data1 = "huff post"
     $redis.set("feed1", data1.to_json)
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
  # NYTimes
  NYT_KEY = "53bbd3a7cce7cbbcedc67e22259f12ee:4:69767384"
  NYT_CALLBACK_URI = "http://127.0.0.1/profile"
  # Weather
  WEATHER_API_KEY = "60e77c41f4f4c6f7"
  # Twitter
  TWITTER_API_KEY = "XNvSWXvC0zEiBrjN6X6lmw5K5"
  TWITTER_API_SECRET = "c4AZ9SccgxLUfhcl9b3uzM4fU5B0WbjGgvvhFTQuVOKpoGMQCM"
  TWITTER_TOKEN = "235247373-1axuRRVCztCGkmdcjSpWzKTznm2333xSsj4FMa18"
  TWITTER_SECRET_TOKEN = "IOn4ikE3MkKomEBZ8VA6rgR3ri7AblG7rqa5NPqAgYlaJ"
  TWITTER_CALLBACK_URI = "http://127.0.0.1/profile"
  TWITTER_CLIENT = Twitter::REST::Client.new do |config|
   config.consumer_key        = TWITTER_API_KEY
   config.consumer_secret     = TWITTER_API_SECRET
   config.access_token        = TWITTER_TOKEN
   config.access_token_secret = TWITTER_SECRET_TOKEN
  end

  ########################
  # GET Routes
  ########################

  get('/') do
    render(:erb, :index)
  end


  get('/dashboard_form') do
    @feeds = ["new_york_times", "twitter", "espn", "bleacher_report", "rotowire", "the_football_guys"]
    if params[:sent] == "true"
      @show_submit_success_message = true
    end
    render(:erb, :dashboard_form)
  end # ends get/dashboard_form


  get('/profile') do
##########API's/RSS's####################
  ##################################
  #NYT_API
  ##############################
      base_url = "http://api.nytimes.com/svc/search/v2/articlesearch.json"
      query = "football"
      begin_date = 20140904
      end_date = 20141131
      @nyt_url = HTTParty.get("#{base_url}?q=#{query}&begin_date=#{begin_date}&end_date=#{end_date}&api-key=#{NYT_KEY}&callback=#{NYT_CALLBACK_URI}").to_json
      @parsed_nyt = JSON.parse(@nyt_url)
      @simple_nyt = @parsed_nyt["response"]["docs"]

    ###########################
    # weather_api
    ###############################
      state = params[:state]
      city = params[:city]
      @weather_url = HTTParty.get("http://api.wunderground.com/api/60e77c41f4f4c6f7/conditions/q/#{state}/#{city}.json")
      @temp_in_f = @weather_url["current_observation"]["temp_f"]

  ###########################
  # Twitter_api
  ##############################
     @tweets = []
     TWITTER_CLIENT.search("MatthewBerryTMR", :result_type => "recent").take(15).each do |tweet|
     @tweets.push(tweet.text)
   end
  #####################################
  # ESPN RSS Feed
  ################################
    @espn_feed = []
    @espn = Feedjira::Feed.fetch_and_parse("http://sports.espn.go.com/espn/rss/nfl/news")
    @espn.entries.first(15).each do |entry|
      @espn_feed.push({title: entry.title.gsub("&#x0024;", "$"),
                      url: entry.url,
                      summary: entry.summary,
                      })
    end
  ###########################
  # Bleacher Report Feed
  ###########################
    @br_feed = []
    @br = Feedjira::Feed.fetch_and_parse("http://bleacherreport.com/articles;feed?tag_id=16")
    @br.entries.first(2).each do |entry|
      @br_feed.push({title: entry.title.gsub("&#x0024;", "$"),
                      url: entry.url,
                      summary: entry.summary,
                      })
    end
  ######################################
  # Rotowire RSS Feed
  #############################
    @roto_feed = []
    @rotowire = Feedjira::Feed.fetch_and_parse("http://www.rotowire.com/rss/news.htm?sport=nfl")
    @rotowire.entries.first(10).each do |entry|
      @roto_feed.push({title: entry.title.gsub("&#x0024;", "$"),
                      url: entry.url,
                      summary: entry.summary,
                      })
    end
    ################################
    # The Football Guys RSS Feed
    ################################
      @fbg_feed = []
      @fbg = Feedjira::Feed.fetch_and_parse("http://rss.footballguys.com/bloggerrss.xml")
      @fbg.entries.first(10).each do |entry|
        @fbg_feed.push({title: entry.title.gsub("&#x0024;", "$"),
                        url: entry.url,
                        summary: entry.summary,
                        })
      end


      render(:erb, :profile) # render for get/profile
  end # ends get('/profile')



  ##################################
  # POST Routes
  ##################################

  post('/dashboard_form') do
    number = $redis.keys.size
    number += 1
    $redis.set("feed#{number}", params["feed"].to_json)
    city = params[:city]
    state = params[:state]
    redirect to("/profile?state=#{state}&city=#{city}")
  end

  post('/') do
    new_user = {
      name: params["name"],
      email: params["email"],
      pic: params["pic"],
    }
    @@users.push(new_user)
    $redis.set("user", new_user.to_json)

    redirect to('/dashboard_form')
  end
##################################






end # ends class
