require 'pry'
require 'rubygems'
require 'sinatra/base'
require 'redis'
require 'json'
require 'uri'


uri = URI.parse(ENV["REDISTOGO_URL"])
$redis = Redis.new({:host     => uri.host,
                    :port     => uri.port,
                    :password => uri.password})

$redis.flushdb

feeds = ["espn", "bleacher_report", "twitter"].to_json
$redis.set("feeds", feeds)
binding.pry
