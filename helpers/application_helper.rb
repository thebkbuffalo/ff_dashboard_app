module ApplicationHelper
  def redis_get(number)
    JSON.parse($redis.get("user:#{number}"))
  end

  def current_user
     session["current_user"]
  end

end # end's module 
