require File.join File.dirname(__FILE__), "../lib/middleware"

class Middleware1
  include ItsyBitsy::Middleware
  def transform
    @body = "1#{ @body }1"
  end
end

class Middleware2
  include ItsyBitsy::Middleware
  def transform
    @body = "2#{ @body }2"
  end
end