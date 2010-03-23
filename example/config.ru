require File.dirname(__FILE__) + '/../lib/itsybitsy'

posts_folder = File.dirname(__FILE__)+"/posts"

app = ItsyBitsy.build do
  folder(posts_folder)
  
  get '/' do
    slugs_for(posts_folder).inject("") do |memo, slug|
      memo + "<p><a href=\'#{slug}\'>A post from the posts folder.</a></p>"
    end
  end
  
  header("<b><h1>ItsyBitsy - a sinatra knock off!</h1></b></ br></ br>")
  
  footer("<h6>An Itsy Production.</h6>")  
end

run app