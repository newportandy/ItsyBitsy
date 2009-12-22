require File.dirname(__FILE__) + '/../lib/itsybitsy'

app = ItsyBitsy.build do
  helper do
    def number_of_spiders num
      "#{num}(!!!)"
    end
  end
  
  get '/' do
    "Hello from ItsyBitsy."
  end
  
  get '/:spider_count' do
    "There are #{number_of_spiders params["spider_count"]} spiders."
  end
end

run app