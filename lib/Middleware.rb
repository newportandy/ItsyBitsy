# ItsyBitsy::Middleware is used to make trivial rack middleware more trivial.
# It assumes that the middleware will manipulate the Body as a string and packages it up
# as an array at the end. Classes that want to use this should implement that transform method
# that should do all of the work of manipulating the request.
module ItsyBitsy
  module Middleware
      def initialize app
        @app = app
      end
      def call env
        @status, @headers, body_array = @app.call env
        @body = ''; body_array.each {|string| @body << string }
        transform
        [ @status, @headers, [ @body ] ]
      end
  end
end