require 'rubygems'
require 'rack'
require 'yaml'

class ItsyBitsy
  def self.build &block
    app = App.new
    app.instance_eval &block
    app
  end
  
  class App
    def initialize
      @simple_cache = {}
      @slugs = {}
      @routes = { :get => {}, :post => {}, :delete => {}, :put => {} }
      @middleware = []
    end
    
    def method_missing method, *args, &block
      [:get, :put, :delete, :post].include?(method) ? add_route( method, args[0], &block) : super
    end
    
    def folder path
      slugs_for_path = []
      Dir.chdir path do
        Dir.glob('*').each do |file|
          file_contents = YAML::load(File.open(file))
          instance_eval "get (\'#{file_contents["Slug"]}\') do \n
            @simple_cache[\'#{file_contents["Slug"]}\'] ||= YAML::load(File.open(\"#{File.join(Dir.pwd, file)}\"))[\'Body\'] \n
            @simple_cache[\'#{file_contents["Slug"]}\'] \n
          end"
          slugs_for_path << file_contents["Slug"]
        end
        @slugs[path] = slugs_for_path
      end
    end
    
    def slugs_for path
      @slugs[path]
    end
    
    def add_route method, matcher, &block
      if matcher.is_a? String
        path_params = matcher.scan(/:(\w+)/).flatten
        matcher = Regexp.new(matcher.gsub(/:(\w+)/, '(\w+)')+'$')
        instance_eval "def matcher.path_params\n#{path_params.inspect}\nend" if path_params.length > 0
      end
      @routes[method][matcher] = block
    end
    
    def helper &block
      instance_eval &block 
    end
    
    def use middlware
      @middleware.unshift middlware
    end
    
    def redirect path
      @response.redirect path
    end
    
    def params
      @request.params
    end
    
    def call env
      app = lambda { |env|
        @request = Rack::Request.new env
        @response = Rack::Response.new
        method = @request.request_method.downcase.to_sym
        path = @request.path_info
        body_proc = find_route path, method
        if body_proc then
          @response.body = body_proc.call || ""
          @response.finish
        else
          @response.status = 404
          @response.body = "I'm sorry we couldn't process your request."
          @response.finish
        end
      }
      @middleware.each do |middleware|
          app = middleware.new app
      end
      app.call env
    end
    
    def find_route path, method
      @routes[method].each do |regex, block|
        match = regex.match path
        next unless match
        if regex.respond_to? :path_params
          regex.path_params.each_with_index do |path_param, index|
            params[path_param] = match[index+1]
          end
        end
        return block
      end
      nil
    end
  end
end