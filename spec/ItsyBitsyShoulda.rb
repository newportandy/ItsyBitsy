require 'rubygems'
require 'test/unit'
require 'shoulda'
require File.dirname(__FILE__) + '/../lib/itsybitsy'
require 'itsybitsymiddleware'

class ItsyBitsyCouldaTest < Test::Unit::TestCase  
  context "An ItsyBitsy instance" do
    setup do
      app = ItsyBitsy.build do
        get( '/' ) { "get" }
        post( '/' ) { "post" }
        delete( '/' ) { "delete" }
        put( '/' ) { "put" }
        get( /\/regex/ ) { "regex" }
        get( '/redirect' ) { redirect '/redirected' }
        get( '/params' ) { params["test_params"] }
        get( '/route_params/:id') { params["id"] }
      end
      @req = Rack::MockRequest.new app
    end
    
    should "respond to HTTP verbs" do
      assert_equal( "get", @req.get( '/' ).body )
      assert_equal( "post", @req.post( '/' ).body )
      assert_equal( "delete", @req.delete( '/' ).body )
      assert_equal( "put", @req.put( '/' ).body )
    end
    
    should "redirect correctly" do
      assert_equal( 302, @req.get( '/redirect' ).status )
      assert_equal( "/redirected", @req.get( '/redirect' ).headers['Location'] )
    end
    
    should "match routes using regular expressions" do
      assert_equal( "regex", @req.get( '/regex' ).body )
    end
    
    should "responde with 404 when it can't find a route" do
      assert_equal( 404, @req.get( '/unknown' ).status )
    end
    
    should "have access to rack's params hash" do
      assert_equal( "test", @req.get( '/params?test_params=test' ).body )
    end
    
    should "use path params" do
      assert_equal( "5", @req.get( '/route_params/5' ).body )
    end
    
    context "with two applications" do
      should "have seperate helpers for each" do
        app1 = ItsyBitsy.build do
          helper do
            def hello
              "hello"
            end
          end
          get( '/' ) { hello }
        end
        app2 = ItsyBitsy.build do
          get( '/' ) { hello }
        end
        @req1 = Rack::MockRequest.new app1
        @req2 = Rack::MockRequest.new app2
        assert_equal( "hello", @req1.get( '/' ).body )
        assert_raise NameError do  @req2.get( '/' ) end
      end
    end
    
    context "that uses middleware" do
      should "use it in the correct order" do
        app = ItsyBitsy.build do
          use Middleware1
          use Middleware2
          get( '/' ) { "get" }
        end
        @req = Rack::MockRequest.new app
        assert_equal( "12get21", @req.get( '/' ).body )
      end
    end 
  end
end