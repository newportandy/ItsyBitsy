require 'rubygems'
require 'rack'
require 'yaml'
require File.dirname(__FILE__) + '/middleware'

module ItsyBitsy
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
    end
    
    def method_missing method, *args, &block
      [:get, :put, :delete, :post].include?(method) ? add_route( method, args[0], &block) : super
    end
    
    def folder path
      slugs_for_path = []
      Dir.chdir path do
        Dir.glob('*').each do |file|
          file_contents = YAML::load(File.open(file))
          instance_eval "get ('#{file_contents["Slug"]}') do
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
    
    def assets path, slug_base
      Dir.chdir path do
        Dir.glob('*').each do |file|
          file_path = File.join(path, file)
          type = Rack::Mime.mime_type(File.extname(file), nil)
          slug = File.join(slug_base, file)
          instance_eval "get (\'#{slug}\') do \n
            @response.headers[\"Itsy-Static\"] = 'true'
            @response.headers[\"Content-type\"] = \"#{type}\" if \"#{type}\".length > 0
            @simple_cache[\'#{slug}\'] ||= File.read(\"#{file_path}\") \n
            @simple_cache[\'#{slug}\'] \n
          end"
        end
      end
    end
    
    def header content
      @header = content
    end

    def footer content
      @footer = content
    end
    
    def add_route method, matcher, &block
      if matcher.is_a? String
        path_params = matcher.scan(/:(\w+)/).flatten
        matcher = Regexp.new('^' + matcher.gsub(/:(\w+)/, '(\w+)') + '$')
        instance_eval "def matcher.path_params\n#{path_params.inspect}\nend" if path_params.length > 0
      end
      @routes[method][matcher] = block
    end
    
    def helper &block
      instance_eval &block 
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
      app = TopNTail.new app
      app.header = @header || ""
      app.footer = @footer || ""
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
  
  #Middleware to add a header/footer to the response.
  class TopNTail 
    include ItsyBitsy::Middleware
    attr_accessor :header, :footer
    def transform
      @body = (@header + @body + @footer) unless @headers['Itsy-Static']
    end
  end
end