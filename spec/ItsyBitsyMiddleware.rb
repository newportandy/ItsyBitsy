class Middleware1
  def initialize app
    @app = app
  end
  def call env
    status, headers, body_array = @app.call env
    body = ''; body_array.each {|string| body << string }
    [ status, headers, "1#{ body }1" ]
  end
end
 
class Middleware2
  def initialize app
    @app = app
  end
  def call env
    status, headers, body_array = @app.call env
    body = ''; body_array.each {|string| body << string }
    [ status, headers, "2#{ body }2" ]
  end
end