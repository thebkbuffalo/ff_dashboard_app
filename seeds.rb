require 'sinatra/base'
require 'json'
require 'pry' if ENV["RACK_ENV"] == "development"
require 'httparty'
require 'redis'
require 'securerandom'
require 'uri'
require 'open-uri'
require 'twitter'
require 'rss'
require 'feedjira'

uri = URI.parse(ENV["REDISTOGO_URL"])
$redis = Redis.new({:host     => uri.host,
                    :port     => uri.port,
                    :password => uri.password})



@feeds = ["new_york_times", "twitter", "espn", "bleacher_report", "rotowire", "the_football_guys"].to_json
$redis.set("feeds", feeds)
